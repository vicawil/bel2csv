module BELCSV
    module_function
    def mapTerms(statement, sublevel, argidx = nil, term = nil, role = nil, entity = nil)
        # Shorthand assignments
        #
        obj = statement.currentobj
        objFunction = obj.fx.short_form
        argidy = 0
        
        if role
            term.role = role
        end
        
        # Handle n-ary (n > 2) terms and unary terms containing terms or statements
        #
        unless statement.keeptogether and obj.arguments.length == 1 and obj.arguments[0].instance_of?(BEL::Language::Parameter)
            term.content = csvCreateRelation(statement)
            term.type = "relation"
            walkTaxonomy(term.content, obj, :function)
            
            # Push top-level terms of a top-level statement or nested statement to children array
            pushToStatementChildren(statement, term, entity)
            
            # Handle n-ary terms
            #
            if obj.arguments.length > 1
                obj.arguments.each do |arg|
                    prevannotId = $annotationId
                    prevrelId = $relationId
                    statement.currentobj = arg
                    
                    # Instantiate term argument entity
                    argobj = OpenStruct::new()
                    argobj.role = "member"
                    
                    if arg.instance_of?(BEL::Language::Term)
                        argFunction = arg.fx.short_form
                        
                        # Treat argument terms of length 1 and having a parameter as annotation, unless modification
                        unless statement.keeptogether and 
                               arg.arguments.length == 1 and 
                               arg.arguments[0].instance_of?(BEL::Language::Parameter) and 
                               !$modifications.include? argFunction
                               
                            argobj.refid = "r" + String(prevrelId)
                            if objFunction == :p
                                case argFunction
                                    when :fus
                                        argobj.role = "fusion"
                                    when :pmod
                                        argobj.role = "proteinModification"
                                    when :sub
                                        argobj.role = "substitution"
                                    when :trunc
                                        argobj.role = "truncation"
                                end
                            end
                        else
                            argobj.refid = "a" + String(prevannotId)
                        end
                    
                    # Treat argument parameters always as annotation
                    elsif arg.instance_of?(BEL::Language::Parameter)
                        argobj.refid = "a" + String(prevannotId)
                        case objFunction
                            when :fus
                                case argidy
                                    when 0
                                        argobj.role = "protein"
                                    when 1
                                        argobj.role = "StartNucleotide"
                                    when 2
                                        argobj.role = "EndNucleotide"
                                end
                            when :pmod
                                case argidy
                                    when 0
                                        argobj.role = "ModificationType"
                                    when 1
                                        argobj.role = "AminoAcidCode"
                                    when 2
                                        argobj.role = "ModificationPosition"
                                end
                            when :sub
                                case argidy
                                    when 0
                                        argobj.role = "CodeVariant"
                                    when 1
                                        argobj.role = "Codon"
                                    when 2
                                        argobj.role = "CodeReference"
                                end
                            when :trunc
                                case argidy
                                    when 0
                                        argobj.role = "TruncationPosition"
                                end
                            when :p
                                case argidy
                                    when 0
                                        argobj.role = "protein"
                                end
                        end
                        incr_argidy = true
                    end
                    
                    term.BEL_relative = term.BEL_relative.sub String(arg), argobj.refid
                    
                    if statement.parentTermId
                         statement.parentChildren << term.content.id
                    end
                    statement.parentTermId = term.content.id
                    statement.parentChildren = term.childrenIds
                    
                    # Recursive call of walkTerm
                    walkTerm(statement, sublevel + 1, nil, objFunction, argidy, argobj.role)
                    
                    # Resetting children and ID of parent term
                    statement.parentTermId = nil
                    statement.parentChildren = nil
                    
                    # Increment argument counter for multiple argument terms
                    if incr_argidy
                        argidy += 1
                    end
                    
                end
                
            # Handle unary terms containing terms (treat arguments as annotations)
            #
            else
                if statement.parentTermId
                    statement.parentChildren << term.content.id
                end
                statement.parentTermId = term.content.id
                statement.parentChildren = term.childrenIds
                argobj = csvUnaryTermParameter(statement, $annotationId, objFunction, argidy, sublevel)
                arg = obj.arguments[0]
                term.BEL_relative = term.BEL_relative.sub String(arg), argobj.refid
                
                # Resetting children and ID of parent term
                statement.parentTermId = nil
                statement.parentChildren = nil
            end
        
        # Handle unary terms containing parameters when keeptogether = true
        # (no argument substitution, no recursive walking, treat as relations when term is a modification function)
        else
            unless $modifications.include? objFunction
                term.content = OpenStruct::new()
                term.type = "annotation"
                term.content.id = "a" + String($annotationId)
                walkTaxonomy(term.content, obj, :function)
                
                # Push top-level terms of a top-level statement or nested statement to children array
                pushToStatementChildren(statement, term, entity)
                
                if statement.parentTermId
                    statement.parentChildren << term.content.id
                end 
                
                increment(:annotation)
                
                term.namespace = obj.arguments[0].ns
                term.value = obj.arguments[0].value
                if statement.equivalence_hash
                    term.bid = mapToBID(term.namespace, term.value, statement.equivalence_hash)
                end
            else
            # Handle single-argument modification functions
                term.content = csvCreateRelation(statement)
                term.type = "relation"
                walkTaxonomy(term.content, obj, :function)
                
                # Push top-level terms of a top-level statement or nested statement to children array
                pushToStatementChildren(statement, term, entity)
                
                if role
                    term.role = role
                end
                
                if statement.parentTermId
                    statement.parentChildren << term.content.id
                end
                statement.parentTermId = term.content.id
                statement.parentChildren = term.childrenIds
                
                case objFunction
                    when :pmod
                        role = "ModificationType"
                    when :fus
                        role = "protein"
                end
                
                argobj = csvUnaryTermParameter(statement, $annotationId, objFunction, argidy, sublevel, role)
                arg = obj.arguments[0]
                term.BEL_relative = term.BEL_relative.sub String(arg), argobj.refid

            end
        end
        return term
    end 
end
