require 'json'
require 'csv'
require_relative 'csv_func_rel_mapping'

# Global variable for namespaces without corresponding mapping hashes in equivalence_hash
$ignore_ns = []
$ignore_entity = {}

# Reset document, annotation, relationship ids
def counterReset()
	$documentId = 1000
	$annotationId = 100
	$relationId = 100
end

# Increment id of given element
def increment(id)
	case id
        when :document
            $documentId += 1
        when :relation
            $relationId += 1
        when :annotation
            $annotationId += 1
    end
end

# Insert linebreak
def breakln(str)
	str << "\n"
end

# Insert empty line
def emptyln(str)
	breakln(str)
	breakln(str)
end

# Put argument error and exit
def csvArgError
	string = <<-EOS
--------------------------------------------------------------------
BEL2CSV converter

Usage: bel2csv.rb -<args> <files>
--------------------------------------------------------------------
Command-line arguments:
b: Treat input file as BEL document, use sequentially incremented
   number as BEL ID.
t: Treat input file as tabulated (CSV), use BEL ID from CSV.
a: Only in combination with t: Do not include sentence ID and PMID 
   as passage infons.
h: Only in combination with t: Don't treat first row as header.
n: Map entity symbol or ID (field `value`) to unique internal 
   BEL identifier (field `BID`). Note: Equivalence files must be 
   placed in /equivalence_files and registered in 
   `equivalence_files.json`.
d: Set the CSV field delimiter to `\\0` (default is `"`). Prevents 
   double quoting of fields containing double quotes and doesn't 
   insert escaping double quotes for the contained double quotes. 
   Note: This is not compliant with the RFC 4180 CSV specification.
k: Don't split pre-terminal abundance functions and entities into relation
   and annotation, represent as single annotation instead.
--------------------------------------------------------------------
	EOS
	puts string
	abort
end

# Instantiate relation pobject
def csvCreateRelation(statement)
	obj = statement.currentobj
	content = OpenStruct::new()
	content.id = "r" + String($relationId)
	increment(:relation)
	return content
end

# Process unary BEL term
def csvUnaryTermParameter(statement, annotationId, objFunction, argidy, sublevel, role = nil)
	obj = statement.currentobj
    relation = statement.relation
	arg = obj.arguments[0]
	statement.currentobj = arg
    argobj = OpenStruct::new()
    unless role
        argobj.role = "self"
    else
        argobj.role = role
    end
	argobj.refid = "a" + String(annotationId)
	walkTerm(statement, sublevel + 1, nil, objFunction, argidy, argobj.role)
	return argobj
end

# Walk taxonomy to determine subtype and type of function or relationship predicate
def walkTaxonomy(termcontent, belobj, type)
    if type == :function
        termcontent.objvalue = belobj.fx.long_form
    elsif type == :relationship
        termcontent.objvalue = belobj.relationship
    end
    
    # Mapping to parent taxon
    termcontent.objsubtype = valueMapToSubtype(termcontent.objvalue)
    termcontent.objtype = subtypeMapToType(termcontent.objsubtype)
end


# Push ID to children array of statement
def pushToStatementChildren(statement, term, entity)
    if entity == :subject or entity == :object
        unless statement.nestedStatement
            statement.childrenIds << term.content.id
        else
            statement.nestedChildrenIds << term.content.id
        end
    end
end


# Map namespace and entity value to unique internal BEL identifier (BID)
def mapToBID(ns, value, equivalence_hash)
    ns = String(ns)
    unless $ignore_ns.include? ns or ($ignore_entity[ns] and $ignore_entity[ns].include? value)
        if equivalence_hash.include? ns
            if equivalence_hash[ns].include? value
                return equivalence_hash[ns][value]
            else
                puts "Error mapping #{value}: No matching equivalence entry in hash #{ns}."
                # Suppress repeat errors
                if $ignore_entity[ns]
                    $ignore_entity[ns] << value
                else
                    $ignore_entity[ns] = [value]
                end
            end
        else 
            puts "Warning: No equivalence hash for namespace #{ns}. Corresponding values are not mapped."
            # Suppress repeat warnings
            $ignore_ns << ns
        end
    end
end

# Populate equivalence hash for namespace/value-to-BID mapping
def readEquivFiles()
    equivHash = {}
    equivJSON = File.read("equivalence_files.json")
    equiv_files = JSON.parse(equivJSON)
    equiv_files.each do |ns, equiv_ns|
        equivHash[ns] = {}
        if equiv_ns.instance_of? Array
            equiv_ns.each do |equiv_file|
                puts "- Reading #{equiv_file}"
                readEquivCSV(equivHash, ns, equiv_file)
            end
        else
            equiv_file = equiv_ns
            puts "- Reading #{equiv_file}"
            readEquivCSV(equivHash, ns, equiv_file)
        end
    end
    return equivHash
end
    
# Parse equivalence file, treat as pipe-separated CSV
def readEquivCSV(equivHash, ns, equiv_file)
    csvTable = CSV.read("equivalence_files/" + equiv_file, {col_sep:"|", quote_char:"\0", headers:true})
    map = false
    csvTable.each do |row|
        # Skip non-CSV header
        if !map and row[0] == "[Values]"
            map = true
        elsif map
            equivHash[ns][row[0]] = row[1]
        end
    end
end
