module BELCSV
    module_function
    def mapParameters(statement, parentFunction = nil, argidx = nil, term = nil, role = nil)
        # Shorthand assignments
        #
        obj = statement.currentobj
        term.content = OpenStruct::new()
        term.type = "annotation"
        term.content.objtype = "parameter"
        term.content.objsubtype = "ModificationArgument"
        
        if role
            term.role = role
        end
        
        case parentFunction
            when :fus
                case argidx
                    when 0
                        term.content.objvalue = "protein"
                    when 1
                        term.content.objvalue = "StartNucleotide"
                    when 2
                        term.content.objvalue = "EndNucleotide"
                end
            when :pmod
                case argidx
                    when 0
                        term.content.objvalue = "ModificationType"
                    when 1
                        term.content.objvalue = "AminoAcidCode"
                    when 2
                        term.content.objvalue = "ModificationPosition"
                end
            when :sub
                case argidx
                    when 0
                        term.content.objvalue = "CodeVariant"
                    when 1
                        term.content.objvalue = "Codon"
                    when 2
                        term.content.objvalue = "CodeReference"
                end
            when :trunc
                case argidx
                    when 0
                        term.content.objvalue = "TruncationPosition"
                end
            else
                term.namespace = obj.ns
                term.value = obj.value
                if statement.equivalence_hash
                    term.bid = mapToBID(term.namespace, term.value, statement.equivalence_hash)
                end
        end
        unless obj.ns.nil?
            term.content.objvalue = "protein"
            term.content.objsubtype = "protein"
        else
            term.content.objsubtype = "ModificationArgument"
        end
        
        term.content.id = "a" + String($annotationId)
        increment(:annotation)
        
        if statement.parentTermId
            statement.parentChildren << term.content.id
        end
        
        return term
    end
end
