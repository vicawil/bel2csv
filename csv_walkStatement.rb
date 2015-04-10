require_relative 'csv_helpers'
require_relative 'csv_walkTerm'

# Initialize Id sequences
$documentId = 1000
$annotationId = 100
$relationId = 100

module BELCSV
    module_function
    
    # Walk statement tree from the root
    def walkStatement(statement)
        
        # Shorthand assignments 
        unless statement.nestedStatement
            obj = statement.obj
        else
            obj = statement.nestedStatement
            statement.insideNestedStatement = true
        end
        
        # Instantiate statement entity
        statementobj = OpenStruct::new()
        statementobj.childrenIds = []
        statementobj.BEL_full = String(obj)
        statementobj.BEL_relative = String(obj)
        statementobj.role = "statement"
        statementobj.content = OpenStruct::new()
        statementobj.content.id = "r" + String($relationId)
        statementobj.content.objvalue = "statement"
        statementobj.content.objsubtype = "statement"
        statementobj.content.objtype = "statement"
        statementobj.type = "relation"
        increment(:relation)

        # Handling of top-level statement entities vs. nested statements (doubly nested statements not supported)
        unless statement.insideNestedStatement
            statement.childrenIds = statementobj.childrenIds
            statement.id = statementobj.content.id
            statement.statementobj = statementobj
        else
            statement.nestedChildrenIds = statementobj.childrenIds
            statement.nestedid = statementobj.content.id
            statement.nestedStatementobj = statementobj
            
            statement.childrenIds << statementobj.content.id
        end
        
        # Nested statement (doubly nested statements not supported)
        #if entity == :subject or entity == :object            
        #end
        
        # Unless there is no object
        unless obj.relationship.nil?
            
            # Instantiate relationship entity
            #
            
            # Handling of relationships of top-level statements vs. nested statements
            unless statement.nestedStatement
                statement.relationship = OpenStruct::new()
                relationship = statement.relationship
                relationship.parentId = statement.id
            else
                statement.nestedRelationship = OpenStruct::new()
                relationship = statement.nestedRelationship
                relationship.parentId = statement.nestedid
            end
            
            relationship.content = OpenStruct::new()
            walkTaxonomy(relationship.content, obj, :relationship)
            relationship.type = "annotation"
            relationship.content.funtype= String(obj.relationship)
            relationship.relationship = obj.relationship
        end
        
        # Walk statement subject
        walkTerm(statement, 0, :subject, nil)
        
         
        # statement.parentTermId = nil

        unless obj.relationship.nil?
            
            # Walk statement object
            walkTerm(statement, 0, :object, nil)
            
            # Enumerate relationship annotation, insert into statement
            relationship.content.id = "a" + String($annotationId)
            unless statement.nestedStatement
                statement.childrenIds.insert(1, relationship.content.id) 
            else
                statement.nestedChildrenIds.insert(1, relationship.content.id)
            end

            increment(:annotation)
            
            statement.terms << relationship
        end
        
        # Append top-level statement entity directly, return nested statement entities to caller,
        # reset nesting variables 
        unless statement.insideNestedStatement
            statement.terms << statementobj
        else
            statement.insideNestedStatement = false
            statement.nestedStatement = nil
            return statementobj
        end
    end
end
