# PasDoc generation

This folder contains PasDoc configuration files for NoReflowTabBar.

## Public API reference

Generate the public API reference from the repository root:

```bat
pasdoc @pasdoc-public.cfg
```

Output:

```text
docs\api\
```

This documentation is intended for application developers using the component.

## Complete maintainer reference

Generate the complete maintainer reference from the repository root:

```bat
pasdoc @pasdoc-complete.cfg
```

Output:

```text
docs\api-complete\
```

This documentation includes internal support layers and is mainly intended for project maintenance.

## Notes

The source file lists are stored separately:

```text
pasdoc-sources-public.txt
pasdoc-sources-complete.txt
```

This avoids PasDoc interpreting source file paths inside the .cfg file as options.
