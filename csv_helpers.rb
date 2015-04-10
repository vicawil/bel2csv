require_relative 'csv_func_rel_mapping'

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
   number as BEL ID
t: Treat input file as tabulated (CSV), use BEL ID from CSV
a: Only in combination with t: Do not include sentence Id and PMID 
   as passage infons.
--------------------------------------------------------------------
	EOS
	puts string
	abort
end

def csvCreateRelation(statement)
	obj = statement.currentobj
	content = OpenStruct::new()
	content.id = "r" + String($relationId)
	increment(:relation)
	return content
end

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

def pushToStatementChildren(statement, term, entity)
    if entity == :subject or entity == :object
        unless statement.nestedStatement
            statement.childrenIds << term.content.id
        else
            statement.nestedChildrenIds << term.content.id
        end
    end
end
