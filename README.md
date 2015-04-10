# BEL2CSV converter

Usage: 
`bel2csv.rb -<args> <files>`
    
## Command-line arguments:
**b**: Treat input file as BEL document, use sequentially incremented
   number as BEL ID
   
**t**: Treat input file as tabulated (CSV), use BEL ID from CSV

**a**: Only in combination with t: Do not include sentence Id and PMID 
   as passage infons.
