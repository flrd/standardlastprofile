# The `slp` dataset was renamed

**\[deprecated\]**

## Details

The electricity dataset `slp` was renamed to
[slp_electricity_profiles](https://flrd.github.io/standardlastprofile/dev/reference/slp_electricity_profiles.md)
in version 2.0.0 and is no longer exported under the old name. Accessing
`slp` still returns the data for now, but emits a deprecation warning.
Use `slp_electricity_profiles`, or
[`standardlastprofile::slp_electricity_profiles`](https://flrd.github.io/standardlastprofile/dev/reference/slp_electricity_profiles.md),
instead.

## See also

[slp_electricity_profiles](https://flrd.github.io/standardlastprofile/dev/reference/slp_electricity_profiles.md)
