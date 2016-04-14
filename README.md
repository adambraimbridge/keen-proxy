# keen-proxy
CDN config for cached proxy for th keen.io API

By default queries are cached for a sensible period determined by the interval and timeframe fo the query

By sending a `Cache-Strategy` header, which accepts values normally set in `Cache-Control-Headers`, caching can
also be manually set (max-age, stale-while-revalidate and stale-if-error can all be set)
