### Added

- Added support for `extraContainers` argument. ([#4432](https://github.com/kubernetes-sigs/external-dns/pull/4432)) _@omerap12_
- Added support for setting `excludeDomains` argument.  ([#4380](https://github.com/kubernetes-sigs/external-dns/pull/4380)) _@bford-evs_

### Changed

- Updated _ExternalDNS_ OCI image version to [v0.14.2](https://github.com/kubernetes-sigs/external-dns/releases/tag/v0.14.2). ([#4541](https://github.com/kubernetes-sigs/external-dns/pull/4541)) _@stevehipwell_
- Updated `DNSEndpoint` CRD. ([#4541](https://github.com/kubernetes-sigs/external-dns/pull/4541)) _@stevehipwell_
- Changed the implementation for `revisionHistoryLimit` to be more generic. ([#4541](https://github.com/kubernetes-sigs/external-dns/pull/4541)) _@stevehipwell_

### Fixed

- Fixed the `ServiceMonitor` job name to correctly use the instance label. ([#4541](https://github.com/kubernetes-sigs/external-dns/pull/4541)) _@stevehipwell_
