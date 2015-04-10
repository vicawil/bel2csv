require 'simple_bioc'
require_relative 'csvhelpers'
require_relative 'csv_mapTerms'
require_relative 'csv_mapParameters'

module BELCSV
    module_function
    
    # Treat modification functions specially
    $modifications = [:fus, :pmod, :sub, :trunc]
        
    # Recursively walk terms and parameters (leaf nodes)
    def walkTerm(statement, sublevel, entity = nil, parentFunction = nil, argidx = nil, role = nil)
        
        # Map subject and object when walkTerm is called non-recursively 
        if entity == :subject
            element = "cause"
            unless statement.nestedStatement
                statement.currentobj = statement.obj.subject
            else
                statement.currentobj = statement.nestedStatement.subject
            end
        elsif entity == :object
            element = "theme"
            unless statement.nestedStatement
                statement.currentobj = statement.obj.object
            else
                statement.currentobj = statement.nestedStatement.object
            end
        end
        
        # Instantiate term entity
        term = OpenStruct::new()
        term.childrenIds = []
        
        # Assign parent ID
        if statement.parentTermId
            term.parentId = statement.parentTermId
        else
            unless statement.nestedStatement
                term.parentId = statement.id
            else
                term.parentId = statement.nestedid
            end
        end
        
        
        # Shorthand assignment
        obj = statement.currentobj
        
        unless statement.nestedStatement
            relation = statement.relation
            statementobj = statement.statementobj
        else
            relation = statement.nestedRelation
            statementobj = statement.nestedStatementobj
        end
        
        term.BEL_full = String(obj)
        term.BEL_relative = String(obj)
        
        # Check if statement is a semantic triple
        if !obj.nil? and !statement.obj.relationship.nil?
            
            # Relative BEL: Statement annotation/relation ID substitution for top-level (subject/object) terms
            if sublevel == 0
                    # Term handling
                    if obj.instance_of?(BEL::Language::Term)
                        # Nested terms are relations unless they are unary (not yet encountered)
                        unless obj.arguments.length == 1 and obj.arguments[0].instance_of?(BEL::Language::Parameter)
                            refid = "r" + String($relationId)
                        else
                            refid = "a" + String($annotationId)
                        end
                    # Nested statement handling
                    elsif obj.instance_of?(BEL::Language::Statement)
                        refid = "r" + String($relationId)
                    end
                
                # Update relative BEL string
                substitutionString = statementobj.BEL_relative.sub term.BEL_full, refid
                
                if entity == :object
                    #strip remaining brackets 
                    substitutionString = substitutionString.tr('()','')
                end
                
                statementobj.BEL_relative = substitutionString
            end
            
            
            ##
            ## Mapping of terms, parameters and nested statements to rows
            ##
            
        
            #
            # Map terms
            #
            if obj.instance_of?(BEL::Language::Term)
                term = mapTerms(statement, sublevel, argidx, term, role, entity)
            
            #
            # Map parameters
            #
            elsif obj.instance_of?(BEL::Language::Parameter)
                term = mapParameters(statement, parentFunction, argidx, term, role)
                
            #
            # Map statements
            #
            
            elsif obj.instance_of?(BEL::Language::Statement)
                statement.parentStatement = statement
                statement.nestedStatement = obj
                term = walkStatement(statement)
            end
            
            # Appending processed entity to term array
        
            unless statement.insideNestedStatement
                statement.terms << term
            else
                statement.parentStatement.terms << term
            end
        
        # Rejecting statements that are not semantic triples
        elsif statement.obj.relationship.nil?
            puts "Note: Skipping #{statement.obj}, single-term statements not (yet) supported."
        end
    end
end
