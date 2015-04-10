module BELCSV
    module_function
    
    def valueMapToSubtype(value)
        abundances = [:abundance, :complexAbundance, :compositeAbundance, :geneAbundance, :microRNAAbundance, :proteinAbundance, :rnaAbundance]
        modifications = [:fusion, :proteinModification, :substitution, :truncation]
        processes = [:biologicalProcess, :pathology]
        transformations = [:cellSecretion, :cellSurfaceExpression, :degradation, :reaction, :translocation]
        activities = [:catalyticActivity, :chaperoneActivity, :gtpBoundActivity, :kinaseActivity, :molecularActivity, :peptidaseActivity, :phosphataseActivity, :ribosylationActivity, :transcriptionalActivity, :transportActivity]
        list_functions = [:list, :products, :reactants]
        causal_relationships = [:decreases, :increases, :causesNoChange, :directlyDecreases, :directlyIncreases]
        correlative_relationships = [:negativeCorrelation, :positiveCorrelation]
        genomic_relationships = [:analogous, :orthologous, :transcribedTo, :translatedTo]
        other_relationships = [:association, :biomarkerFor, :hasComponent, :hasComponents, :hasMember, :hasMembers, :isA, :prognosticBiomarkerFor, :rateLimitingStepOf, :subProcessOf]
        direct_relationships_injected = [:actsIn, :hasModification, :hasProduct, :hasVariant, :reactantIn, :translocates, :includeses]
        
        subtypes = { "abundance": abundances
                     "modification": modifications
                     "process": processes
                     "transformation": transformations
                     "activity": activities
                     "list function": list_functions
                     "causal relationship": causal_relationships
                     "correlative relationship": correlative_relationships
                     "genomic relationship": genomic_relationships
                     "other relationship": other_relationships
                     "direct relationship injected": direct_relationships_injected
                    }
                    
        subtypes.each do |subtype, values|
            if value in values
                return subtype
            end
        end
        return nil
    end
    
    def valueMapToType(value)
    
        functions = [:"abundance", :"modification", :"process", :"activity", :"list function"]
        relationships = [:"causal relationship", :"correlative relationship", :"genomic relationship", :"other relationship", :"direct relationship injected"]
        
        types = {function: functions,
                 relationship: relationships}
        
        subtype = valueMapToSubtype(value)
        
        types.each do |type, values|
            if subtype in values
                return type
            end
        end
        return nil
    end
   
   end 
end
