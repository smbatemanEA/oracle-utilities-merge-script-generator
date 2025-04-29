# oracle-utilities-merge-script-generator
Dynamic generator for Oracle MERGE scripts aligned to Oracle Utilities Application Framework (OUAF) standards, handling Maintenance Object (MO) JSON parsing, key-based ON clauses, and full datatype mappings.

## Overview

This project provides a dynamic, SQL-based generator for creating fully functional and properly formatted MERGE scripts designed for Oracle Utilities Generalized Data Export (GDE) Maintenance Objects (MOs).

Instead of manually building MERGE scripts, this tool generates them automatically based on target table structure, indexes, and Oracle Utilities naming conventions.

## Features
- Supports dynamic ON clause generation based on W1%P0 unique indexes
- Automatically builds JSON_TABLE mappings with datatype handling
- Properly handles _DTTM (timestamp) and _DT (date) fields
- Excludes key fields from UPDATE SET to preserve data integrity
- Fully aligns to Oracle Utilities Application Framework (OUAF) best practices
- Output is ready-to-compile PL/SQL procedures

## Version
**v1.0.0** — Production ready

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Author
Created by Sheldon Bateman, with AI assistance for technical implementation and optimization.
