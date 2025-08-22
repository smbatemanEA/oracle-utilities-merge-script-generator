# oracle-utilities-merge-script-generator
Dynamic generator for Oracle MERGE scripts aligned to Oracle Utilities Application Framework (OUAF) standards, handling Maintenance Object (MO) JSON parsing, key-based ON clauses, and full datatype mappings.

## Overview

This project provides a dynamic, SQL-based generator for creating fully functional and properly formatted MERGE scripts designed for Oracle Utilities Generalized Data Export (GDE) Maintenance Objects (MOs).

Instead of manually building MERGE scripts, this tool generates them automatically based on target table structure, indexes, and Oracle Utilities naming conventions.

## Features
- Supports dynamic ON clause generation based on W1%P0 unique indexes
- Automatically builds JSON_TABLE mappings with datatype handling
- Properly handles _DTTM (timestamp) and _DT (date) fields via a custom function that normalizes dates and timestamps
- Excludes key fields from UPDATE SET to preserve data integrity
- Fully aligns to Oracle Utilities Application Framework (OUAF) best practices
- Output is ready-to-compile PL/SQL procedures

### 19c Version
**v19c.x.x** related files are specifically for Autonomous DB Live Feeds into a 19c ATP workload. Dependent DDLs and Procedures are included. 

### 23ai Version
**v23ai.x.x** — Specifically for Autonomous DB Live Feeds into a 23ai ATP workload. Dependent DDLs and Procedures included. 23ai does things differently - specifically, it loads JSON into a collection table. This requires a different approach than 19c.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Author
Created by Sheldon Bateman. I used ChatGPT 4o Model to help me with some of the SQL I wasn't fluent with, and debugging when errors were thrown. The entire design was was my own. This project was as much of a test of how AI is or isn't helpful as it was for me to create something pretty cool. If you find this helpful, feel free to do something nice for someone else, a random stranger perhaps. Be kind.
