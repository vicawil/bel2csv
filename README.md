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
