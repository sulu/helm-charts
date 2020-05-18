vcl 4.0;

C{
    #include <stdlib.h>
}C

acl invalidators {
  "10.0.0.0"/8; # TODO make this configurable
}

backend default {
    .host = "{{ include "sulu.fullname" . }}";
    .port = "{{ .Values.app.service.port }}";
}

sub vcl_recv {
    if (req.method == "PURGE") {
        if (!client.ip ~ invalidators) {
            return (synth(405, "Not allowed"));
        }

        return (purge);
    }

    if (req.method == "BAN") {
        if (!client.ip ~ invalidators) {
            return (synth(405, "Not allowed"));
        }

        if (req.http.x-cache-tags) {
            ban("obj.http.x-host ~ " + req.http.x-host
                + " && obj.http.x-url ~ " + req.http.x-url
                + " && obj.http.content-type ~ " + req.http.x-content-type
                + " && obj.http.x-cache-tags ~ " + req.http.x-cache-tags
            );
        } else {
            ban("obj.http.x-host ~ " + req.http.x-host
                + " && obj.http.x-url ~ " + req.http.x-url
                + " && obj.http.content-type ~ " + req.http.x-content-type
            );
        }

        return (synth(200, "Banned"));
    }

    {{ if .Values.varnish.authorization -}}
    # move authorization to varnish https://gist.github.com/section-io-gists/f553f548245848387feb200de709bc90
    # enables basic-auth in front of the whole application (inclusive caching)
    # authentication should not be required for ban/purge requests
    if (!req.http.Authorization ~ "Basic {{ .Values.varnish.authorization|b64enc }}"
        {{- range .Values.varnish.authorizationExcludedUserAgents -}}
        && !req.http.User-Agent ~ {{ .|quote }}
        {{- end -}}
    ) {
        # This is checking for base64 encoded username:password combination
        return(synth(401, "Authentication required"));
    }

    unset req.http.Authorization;
    {{- end }}

    // Add a Surrogate-Capability header to announce ESI support.
    set req.http.Surrogate-Capability = "abc=ESI/1.0";

    {{ range .Values.varnish.vary -}}
    set req.http.{{ .header }} = regsub(req.http.Cookie, ".*{{ .cookie }}=([^;]+).*", "\1");
    {{ end }}

    # strip away utm parameters from url https://www.getpagespeed.com/server-setup/varnish/strip-query-parameters-varnish
    if (req.url ~ "(\?|&)(gclid|utm_[a-z]+)=") {
        set req.url = regsuball(req.url, "(gclid|utm_[a-z]+)=[-_A-z0-9+()%.]+&?", "");
        set req.url = regsub(req.url, "[?|&]+$", "");
    }

    // Remove all cookies except the session ID.
    if (req.http.Cookie) {
        set req.http.Cookie = ";" + req.http.Cookie;
        set req.http.Cookie = regsuball(req.http.Cookie, "; +", ";");
        set req.http.Cookie = regsuball(req.http.Cookie, ";({{ .Values.varnish.sessionCookie }})=", "; \1=");
        set req.http.Cookie = regsuball(req.http.Cookie, ";[^ ][^;]*", "");
        set req.http.Cookie = regsuball(req.http.Cookie, "^[; ]+|[; ]+$", "");

        if (req.http.Cookie == "") {
            // If there are no more cookies, remove the header to get page cached.
            unset req.http.Cookie;
        }
    }

    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }

    if (req.http.Authorization) {
        return (pass);
    }

    # Force the lookup, the backend must tell not to cache or vary on all
    # headers that are used to build the hash.
    return (hash);
}

sub vcl_hash {
    // Handle SSL offloading
    if (req.http.X-Forwarded-Proto) {
        hash_data(req.http.X-Forwarded-Proto);
    }
}

sub vcl_backend_response {
    {{ if .Values.varnish.grace -}}
    # Enable grace period (see https://varnish-cache.org/docs/4.1/users-guide/vcl-grace.html)
    set beresp.grace = {{ .Values.varnish.grace }};

    {{ end -}}

    {{ if .Values.varnish.keep -}}
    # Enable keep period (see https://varnish-cache.org/docs/4.1/users-guide/vcl-grace.html)
    set beresp.keep = {{ .Values.varnish.grace }};

    {{ end -}}

    # Set ban-lurker friendly custom headers
    set beresp.http.x-url = bereq.url;
    set beresp.http.x-host = bereq.http.host;

    // Check for ESI acknowledgement and remove Surrogate-Control header
    if (beresp.http.Surrogate-Control ~ "ESI/1.0") {
        unset beresp.http.Surrogate-Control;
        set beresp.do_esi = true;
    }

    if (beresp.http.X-Reverse-Proxy-TTL) {
        /*
         * Note that there is a ``beresp.ttl`` field in VCL but unfortunately
         * it can only be set to absolute values and not dynamically. Thus we
         * have to resort to an inline C code fragment.
         *
         * As of Varnish 4.0, inline C is disabled by default. To use this
         * feature, you need to add `-p vcc_allow_inline_c=on` to your Varnish
         * startup command.
         */
        C{
            const char *ttl;
            const struct gethdr_s hdr = { HDR_BERESP, "\024X-Reverse-Proxy-TTL:" };
            ttl = VRT_GetHdr(ctx, &hdr);
            VRT_l_beresp_ttl(ctx, atoi(ttl));
        }C

        unset beresp.http.X-Reverse-Proxy-TTL;
    }
}

sub vcl_deliver {
    if (!resp.http.x-cache-debug) {
        unset resp.http.x-url;
        unset resp.http.x-host;
        unset resp.http.x-cache-tags;
        unset resp.http.x-powered-by;
    }

    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }
}

{{ if .Values.varnish.authorization -}}
# move authorization to varnish https://gist.github.com/section-io-gists/f553f548245848387feb200de709bc90
# enables basic-auth in front of the whole application (inclusive caching)
sub vcl_synth {
    if (resp.status == 401) {
        set resp.status = 401;
        set resp.http.WWW-Authenticate = "Basic realm={{ .Release.Name }}";

        return(deliver);
    }
}

{{ end -}}
