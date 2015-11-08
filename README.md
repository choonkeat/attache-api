# Attache/API

[![Gem Version](https://badge.fury.io/rb/attache-api.svg)](https://badge.fury.io/rb/attache-api)
[![Build Status](https://travis-ci.org/choonkeat/attache-api.svg?branch=master)](https://travis-ci.org/choonkeat/attache-api)

Core library and tests to integrate with an [attache](https://github.com/choonkeat/attache) server; to be leveraged by client libraries e.g. [attache_rails](https://github.com/choonkeat/attache_rails) which integrates with ActiveRecord

## Testing against an attache-compatible server

Test suite will interact with a server when `ATTACHE_URL` is explicitly set. This can conveniently check if a server at a given URL is attache-compatible. To run such compatibility check, execute the test suite with `ATTACHE_URL` and `ATTACHE_SECRET_KEY` set to the correct values

```
ATTACHE_URL=http://localhost:9292 ATTACHE_SECRET_KEY=topsecret rake
```

NOTE: the test suite will upload a small jpg file and delete it immediately, for several iterations.

## Environment variables

Important variables:

- `ATTACHE_URL` url pointing to the attache server instance, default `http://localhost:9292`
- `ATTACHE_SECRET_KEY` optional shared secret with attache server, default no secret

Optional variables:

- `ATTACHE_UPLOAD_DURATION` browser upload signature expiration duration, default 3 hours; used in conjunction with `ATTACHE_SECRET_KEY`
- `ATTACHE_UPLOAD_URL`, `ATTACHE_DOWNLOAD_URL`, `ATTACHE_DELETE_URL` specific urls pointing to upload, download, delete API end points, default `{ATTACHE_URL}/upload`, `{ATTACHE_URL}/view`, `{ATTACHE_URL}/delete`
- `ATTACHE_DISCARD_FAILURE_RAISE_ERROR` when set, raises an error if deleting of files causes an error. by default, deletion errors are discarded

## License

MIT

