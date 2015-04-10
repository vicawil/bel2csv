#!/usr/bin/env ruby
# vim: ts=2 sw=2

begin
    require 'bel'
    rescue LoadError
        puts "Error: bel2csv requires the ruby gem bel.rb (https://github.com/OpenBEL/bel.rb)"
        abort
end
require 'ostruct'
require 'csv'
require 'date'
require_relative 'csv_walkStatement'
require_relative 'csv_tabulatedConversion'

def main
    argv = ARGV[0]
    
    unless ARGV.length == 0
        args = argv.split ""
    else
        csvArgError
    end
    
    unless args[0] == '-' and (args.include? 't' or args.include? 'b')
		csvArgError
	end
    
    fileArray = ARGV[1..-1]
    
    puts "Files to process: #{fileArray.length}"
    fileArray.each do |infile|
        outfile = infile.rpartition(".")[0] + ".csv"
        
        # CSV parameters
        #
        
        # CSV header
        head_array = ["PMID", "Sentence ID", "BEL ID", "Entity ID", "Parent ID", "type", "role", "object type", "object subtype", "object value", "namespace", "value", "BEL (full)", "BEL (relative)", "children IDs"]
        
        # CSV output file parameters (tabbed CSV with header)
        csvOutOptions = { col_sep:        "\t",
                          headers:        head_array,
                          write_headers:  true}
        csvOutFile = CSV.open(outfile, "wb", options=csvOutOptions)
        
        puts "Processing #{infile} ..."
        
        if args.include? 'b'
            # Treating input as standard BEL document
            belfile = File.new(infile, "r")
        elsif args.include? 't'
            # Treating input as tabulated/tabbed CSV
            puts "Generating BEL from tabulated file ..."
            csvObj = csvReader(infile)
            belfile = belBuilder(csvObj)
        end
        
        # Shortnames for namespaces
        namespace_mapping = {GO:GOBP}
        
        # Extract BEL statements from the document
        puts "Parsing BEL document ..."
        
        statements = []
        BEL::Script.parse(belfile, namespace_mapping) do |obj|
            if obj.instance_of?(BEL::Language::Statement)
                statements << obj
            end
        end
    
        # Handle invalid input file, indicate errors in BEL statements
        if statements.length == 0
            puts "Error: Invalid or empty BEL document #{infile}. Use argument 't' for tabulated source data."
            abort
        elsif args.include? 't' and statements.length < csvObj.linecount
            puts "Warning: Only #{statements.length} of #{csvObj.linecount} BEL statements in the source file have been parsed. \nPossible error in the BEL syntax on line #{statements.length + 2} of #{infile}."
        end
        
        # Convert statements to CSV rows
        puts "Building CSV structure ..."
        statements.each_with_index do |obj, idx|
            
            # Prepare abstract statement object
            #
            statementObj = OpenStruct.new()
            statementObj.obj = obj
            statementObj.csv = csvOutFile
            
            # Use sequential number for column BEL ID if input is a BEL document
            # Otherwise, use provided BEL ID from tabulated source file
            if args.include? 'b'
                statementObj.statement_id = "b" + String($documentId)
                increment(:document)
            elsif args.include? 't'
                bel_meta = csvObj.rowArray.shift
                statementObj.statement_id = bel_meta.bel_id
                statementObj.sentence = bel_meta.sentence
                unless args.include? 'a'
                    statementObj.sentence_id = bel_meta.sentence_id
                    statementObj.pmid = bel_meta.pmid
                end
            end
            statementObj.terms = []
        
            # Process statement (main call)
            BELCSV.walkStatement(statementObj)
            
            # Write statement terms, relationships and nested statements to CSV, row by row
            statementObj.terms.each do |term|
            term.childrenIds = String(term.childrenIds).tr('["]', "")
               
                csvOutFile << [statementObj.pmid,
                               statementObj.sentence_id,
                               statementObj.statement_id,
                               term.content.id,
                               term.parentId,
                               term.type,
                               term.role,
                               term.content.objtype,
                               term.content.objsubtype,
                               term.content.objvalue, 
                               term.namespace,
                               term.value,
                               term.BEL_full,
                               term.BEL_relative,
                               term.childrenIds.length == 0? nil : term.childrenIds
                              ]
            end
    
            # Simple progress indicator for large input data sets
            if idx != 0 and idx % 1000 == 0
                puts "Processed #{idx} statements ..."
            end
        end
        csvOutFile.close()
        counterReset()
    end
    puts "Done."
    exit! # Need to force exit for large tabulated input data sets (cause unknown)
end

if __FILE__ == $0
    main()
end
