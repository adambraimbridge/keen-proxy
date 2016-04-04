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
	set req.http.Rhys-Control = "RhysRhys";
	return(lookup);
}

sub vcl_fetch {
	#FASTLY fetch
	# set req.http.Rhys-Control = "RHYSRHYSRHYS";
	# if (req.request == "OPTIONS") {
	# 	return (deliver);
	# }

	# if (beresp.status >= 500 && beresp.status < 600) {
	# 	# deliver stale if the object is available
	# 	if (stale.exists) {
	# 		return(deliver_stale);
	# 	}

	# 	# Attempt restart
	# 	if (req.restarts < 1 && (req.request == "GET" || req.request == "HEAD")) {
	# 		restart;
	# 	}
	# }

	# if (req.restarts > 0 ) {
	# 	set beresp.http.Fastly-Restarts = req.restarts;
	# }


	# if (beresp.http.Set-Cookie) {
	# 	set req.http.Fastly-Cachetype = "SETCOOKIE";
	# 	return (pass);
	# }



	# if (req.http.Cache-Control && req.http.Cache-Control ~ "stale-while-revalidate" ) {
	# 	set beresp.http.Surrogate-Control = req.http.Cache-Control;
	# } else if (req.http.Cache-Control && req.http.Cache-Control !~ "no-cache") {
	# 	set beresp.http.Surrogate-Control = req.http.Cache-Control {", stale-while-revalidate=300"};
	# } else {
	# 	set req.http.Stale-While-Revalidate = "stale-while-revalidate=300";
	# 	if (req.url ~ "&timeframe=this") {


	# 		if (req.url ~ "&interval=minutely") {
	# 			# 1 minute cache
	# 			set req.http.Cache-Control = "max-age=300";
	# 			set req.http.Stale-While-Revalidate = "stale-while-revalidate=60";
	# 		} else if (req.url ~ "&interval=hourly") {
	# 			# 15 minute cache
	# 			set req.http.Cache-Control = "max-age=900";
	# 		} else if (req.url ~ "&interval=daily") {
	# 			# 3 hour cache
	# 			set req.http.Cache-Control = "max-age=10800";
	# 		} else if (req.url ~ "&interval=weekly") {
	# 			# 1 day cache
	# 			set req.http.Cache-Control = "max-age=86400";
	# 		} else if (req.url ~ "&interval=monthly") {
	# 			# 1 week cache
	# 			set req.http.Cache-Control = "max-age=604800";
	# 		} else if (req.url ~ "&interval=yearly") {
	# 			# 1 week cache
	# 			set req.http.Cache-Control = "max-age=604800";
	# 		} else {
	# 			# default to 30 minute cache
	# 			set req.http.Cache-Control = "max-age=1800";
	# 		}
	# 	} else {
	# 		# Longer caches when requesting previous or relative timeframes
	# 		if (req.url ~ "&interval=minutely") {
	# 			# 5 minute cache
	# 			set req.http.Cache-Control = "max-age=300";
	# 			set req.http.Stale-While-Revalidate = "stale-while-revalidate=60";
	# 		} else if (req.url ~ "&interval=hourly") {
	# 			# 1 hour cache
	# 			set req.http.Cache-Control = "max-age=3600";
	# 		} else if (req.url ~ "&interval=daily") {
	# 			# 8 hour cache
	# 			set req.http.Cache-Control = "max-age=28800";
	# 		} else if (req.url ~ "&interval=weekly") {
	# 			# 7 day cache
	# 			set req.http.Cache-Control = "max-age=604800";
	# 		} else if (req.url ~ "&interval=monthly") {
	# 			# 28 day cache
	# 			set req.http.Cache-Control = "max-age=16934400";
	# 		} else if (req.url ~ "&interval=yearly") {
	# 			# 28 day cache
	# 			set req.http.Cache-Control = "max-age=16934400";
	# 		} else {
	# 			# default to 30 minute cache
	# 			set req.http.Cache-Control = "max-age=1800";
	# 		}
	# 	}

	# 	set beresp.http.Surrogate-Control = req.http.Cache-Control {", "} req.http.Stale-While-Revalidate;
	# }

	# if (beresp.http.Surrogate-Control !~ "stale-if-error") {
	# 	set beresp.http.Surrogate-Control = beresp.http.Surrogate-Control {", stale-if-error=14400"};
	# }

	# set beresp.http.Surrogate-Control = "max-age=300";

	set beresp.http.Rhys-Controls = req.http.Rhys-Control;


	# if (beresp.status == 500 || beresp.status == 503) {
	# 	set req.http.Fastly-Cachetype = "ERROR";
	# 	set beresp.ttl = 1s;
	# 	set beresp.grace = 5s;
	# }

	return (deliver);
}

sub vcl_hit {
	#FASTLY hit

	if (!obj.cacheable) {
		return(pass);
	}
	# set req.http.X-TTL = obj.ttl;
	set req.http.Rhys-Controls = obj.http.Rhys-Controls;

	return(deliver);
}

sub vcl_miss {
	#FASTLY miss
	return(fetch);
}

sub vcl_deliver {

	# FASTLY deliver
	set resp.http.Rhys-Controls = req.http.Rhys-Controls;
	set resp.http.Rhys-Control = req.http.Rhys-Control;

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

