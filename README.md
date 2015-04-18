# BEL2CSV converter

Usage: 
`bel2csv.rb -<args> <files>`
    
## Command-line arguments:
**b**: Treat input file as BEL document, use sequentially incremented
   number as BEL ID.
  
**t**: Treat input file as tabulated (CSV), use BEL ID from CSV.

**a**: Only in combination with t: Do not include sentence Id and PMID 
   as passage infons.

**n**: Map entity symbol or ID (field `value`) to unique internal 
   BEL identifier (field `BID`). Note: Equivalence files must be placed 
   in /equivalence_files and registered in equivalence_files.json .

**d**: Set the CSV field delimiter to `\\0` (default is `"`). Prevents 
   double quoting of fields containing double quotes and doesn't 
   insert escaping double quotes for the contained double quotes. 
   Note: This is not compliant with the RFC 4180 CSV specification.
