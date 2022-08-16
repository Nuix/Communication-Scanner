
Communications Scanner
======================

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0) ![This script was last tested in Nuix 9.8](https://img.shields.io/badge/Script%20Tested%20in%20Nuix-9.8-green.svg)

View the GitHub project [here](https://github.com/Nuix/Communication-Scanner) or download the latest release [here](https://github.com/Nuix/Communication-Scanner/releases).

# Overview

**Written By:** Jason Wells

This script scans the communication properties of email items and tags those which meet specified criteria regarding their addresses.

# Getting Started

## Setup

Begin by downloading the latest release.  Extract the contents of the archive into your Nuix scripts directory.  In Windows the script directory is likely going to be either of the following:

- `%appdata%\Nuix\Scripts` - User level script directory
- `%programdata%\Nuix\Scripts` - System level script directory

# Settings

When the script is ran a dialog will be displayed where the user may specify the following settings.

## Main Tab

| Setting | Description |
|---------|-------------|
| **Scope Query** | This query will be ran to determine the items which the script scans. **Note:** If items were selected in the results view when the script was started this option is not available because the script will scan the selected items. |

**Note**: Since this script inspects the communication of items, items without a communication are skipped while scanning.  Additionally, as with all queries ran through the scripting API, excluded items are not handled.  If you wish to prevent excluded items from being scanned include `has-exclusion:0` in your query.

## Addresses Tab

| Setting | Description |
|---------|-------------|
| **Require Addresses** | When checked scanned items will only qualify when they meet the specified address requirements and have at least 1 address. |
| **All selected must be present, no others may be present** | Items only qualify if they have all email addresses you have selected and no other email addresses. |
| **All selected must be present, others may also be present** | Items only qualify if they have all email addresses you have selected.  Items are allowed to have additional addresses which you did not select. |
| **Ignore items with any address other than these** | Items only qualify if they only have addresses which are present in your selection.  Not required to have all selected addresses present. |
| **Require addresses other than these** | Items only qualify if they have addresses outside those in your selection.  Not required to have all addresses which you did not select. |
| **Required Addresses** | Your selection of email addresses used by the address filtering options. |
| **Fields Scanned** | Determines which address fields are scanned. Only addresses in the selected fields will be considered.  Contents of un-selected address fields will be ignored.  At least 1 must be selected. |

## Domains Tab

| Setting | Description |
|---------|-------------|
| **Require Domains** | When checked scanned items will only qualify when they meet the specified domain requirements and have at least 1 address. |
| **All selected must be present, no others may be present** | Items only qualify if they have all email address domains you have selected and no other email address domains. |
| **All selected must be present, others may also be present** | Items only qualify if they have all email address domains you have selected.  Items are allowed to have additional address domains which you did not select. |
| **Ignore items with any domain other than these** | Items only qualify if they only have address domains which are present in your selection.  Not required to have all selected domains present. |
| **Require domains other than these** | Items only qualify if they have address domains outside those in your selection.  Not required to have all address domains which you did not select. |
| **Required Domains** | Your selection of email address domains used by the domain filtering options. |
| **Fields Scanned** | Determines which address fields are scanned. Only addresses in the selected fields will be considered.  Contents of un-selected address fields will be ignored.  At least 1 must be selected. |

**Note**: Email address domains are obtained from a given address using the regular expression `^.*(@[^@]+)$` and using the value of the first capture group.  If this regular expression does not find a match, the domain for the given item will treated as the value `UNKNOWN DOMAIN`.

## Subject Tab

| Setting | Description |
|---------|-------------|
| **Match Subject** | When checked, an item only qualifies if it has the property "Subject" which matches the regular expression pattern you specify. |
| **Regex Pattern** | The Ruby regular expression tested against the subject value of an item when `Match Subject` is checked.  Unlike Nuix query regular expressions, this regex is matched against the entire value of the subject property.  This allows for things like matching against the beginning and ending of the line rather than just specific terms. |
| **Case insensitive** | Whether the regular expression should be case sensitive or not. |

## Reporting Tab

| Setting | Description |
|---------|-------------|
| **Include Family Members** | Whether to include the family members of qualified items before tagging. |
| **Tag** | The tag to be applied to qualified items. |
| **Record Address List as Custom Metadata** | When checked, each item scanned will have a list of distinct email addresses recorded as a custom metadata field. |
| **Address List Field Name** | Specified the name of the custom metadata field when **Record Address List as Custom Metadata** is checked. |

# Cloning this Repository

This script relies on code from [Nx](https://github.com/Nuix/Nx) to present a settings dialog and progress dialog.  This JAR file is not included in the repository (although it is included in release downloads).  If you clone this repository, you will also want to obtain a copy of Nx.jar by either:
1. Building it from [the source](https://github.com/Nuix/Nx)
2. Downloading an already built JAR file from the [Nx releases](https://github.com/Nuix/Nx/releases)

Once you have a copy of Nx.jar, make sure to include it in the same directory as the script.

# License

```
Copyright 2022 Nuix

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
