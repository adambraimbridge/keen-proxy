# backend set up in fastly ui in order to enable shielding
# backend keen_io {
# 	.connect_timeout = 10s;
# 	.dynamic = true;
# 	.port = "80";
# 	.host = "api.keen.io";
# 	.host_header = "api.keen.io";
# 	.first_byte_timeout = 60s;
# 	.max_connections = 1000;
# 	.between_bytes_timeout = 10s;
# }

sub vcl_recv {
	#FASTLY recv

	# set req.backend = keen_io;
	set req.http.Host = "api.keen.io";

	# Force SSL
	if (!req.http.Fastly-SSL) {
		error 801 "Force TLS";
	}

	set req.http.Protocol = "https://";

	return(lookup);
}

sub vcl_fetch {
	#FASTLY fetch
	if (req.request == "OPTIONS") {
		return (deliver);
	}
	if (beresp.status >= 500 && beresp.status < 600) {
		# deliver stale if the object is available
		if (stale.exists) {
			return(deliver_stale);
		}

		# Attempt restart
		if (req.restarts < 1 && (req.request == "GET" || req.request == "HEAD")) {
			restart;
		}
	}
	if(req.restarts > 0 ) {
		set beresp.http.Fastly-Restarts = req.restarts;
	}

	if (beresp.http.Set-Cookie) {
		set req.http.Fastly-Cachetype = "SETCOOKIE";
		return (pass);
	}

	if (req.http.Cache-Strategy) {
		set beresp.http.Cache-Strategy = "custom";
		set beresp.stale_while_revalidate = 5m;
		set beresp.ttl = 30m;
		set beresp.stale_if_error = 48h;

		if (req.http.Cache-Strategy ~ "max-age=([0-9]+)") {
		  set beresp.ttl = std.time(re.group.1, 30m);
		}
		if (req.http.Cache-Strategy ~ "stale-while-revalidate=([0-9]+)") {
		  set beresp.stale_while_revalidate = std.time(re.group.1, 5m);
		}
		if (req.http.Cache-Strategy ~ "stale-if-error=([0-9]+)") {
		  set beresp.stale_if_error = std.time(re.group.1, 48h);
		}
	} else if (req.url ~ "&timeframe=this") {
		set beresp.http.Cache-Strategy = "this";
		if (req.url ~ "&interval=minutely") {
			set beresp.ttl = 5m;
			set beresp.stale_while_revalidate = 1m;
		} else if (req.url ~ "&interval=hourly") {
			set beresp.ttl = 15m;
			set beresp.stale_while_revalidate = 5m;
		} else if (req.url ~ "&interval=daily") {
			set beresp.ttl = 3h;
			set beresp.stale_while_revalidate = 5m;
		} else if (req.url ~ "&interval=weekly") {
			set beresp.ttl = 1d;
			set beresp.stale_while_revalidate = 5m;
		} else if (req.url ~ "&interval=monthly") {
			set beresp.ttl = 7d;
			set beresp.stale_while_revalidate = 5m;
		} else if (req.url ~ "&interval=yearly") {
			set beresp.ttl = 7d;
			set beresp.stale_while_revalidate = 5m;
		} else {
			# apply the default ttl
			set beresp.ttl = 30m;
		}
		set beresp.stale_if_error = 4h;
	} else {
		set beresp.http.Cache-Strategy = "prev";
		# Longer caches when requesting previous or relative timeframes
		if (req.url ~ "&interval=minutely") {
			set beresp.ttl = 5m;
			set beresp.stale_while_revalidate = 1m;
		} else if (req.url ~ "&interval=hourly") {
			set beresp.ttl = 1h;
			set beresp.stale_while_revalidate = 5m;
		} else if (req.url ~ "&interval=daily") {
			set beresp.ttl = 8h;
			set beresp.stale_while_revalidate = 5m;
		} else if (req.url ~ "&interval=weekly") {
			set beresp.ttl = 7d;
			set beresp.stale_while_revalidate = 5m;
		} else if (req.url ~ "&interval=monthly") {
			set beresp.ttl = 28d;
			set beresp.stale_while_revalidate = 5m;
		} else if (req.url ~ "&interval=yearly") {
			set beresp.ttl = 28d;
			set beresp.stale_while_revalidate = 5m;
		} else {
			# apply the default ttl
			set beresp.ttl = 30m;
		}
		# apply the default ttl
		set beresp.ttl = 30m;
		set beresp.stale_if_error = 48h;
	}
	# set beresp.http.Cache-Strategy = "after";
	if (beresp.status == 500 || beresp.status == 503) {
		set req.http.Fastly-Cachetype = "ERROR";
		set beresp.ttl = 1s;
		set beresp.grace = 5s;
	}

	return (deliver);
}

sub vcl_hit {
	#FASTLY hit
	if (!obj.cacheable) {
		return(pass);
	}

	return(deliver);
}

sub vcl_miss {
	#FASTLY miss
	return(fetch);
}

sub vcl_deliver {

	#FASTLY deliver

	if (req.request == "OPTIONS") {
		set resp.status = 202;
	}
	set resp.http.Access-Control-Allow-Origin = "*";
	if (req.http.Error-Message){
		set resp.http.Error-Message = req.http.Error-Message;
	}

	if (req.http.X-TTL) {
		set resp.http.X-TTL = req.http.X-TTL;
	}

	return (deliver);
}

sub vcl_error {
	#FASTLY error
}

sub vcl_pass {
	#FASTLY pass
}

