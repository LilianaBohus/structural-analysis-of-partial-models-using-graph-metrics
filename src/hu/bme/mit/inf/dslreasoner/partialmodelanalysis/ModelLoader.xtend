package hu.bme.mit.inf.dslreasoner.partialmodelanalysis

import hu.bme.mit.inf.dslreasoner.domains.yakindu.sgraph.yakindumm.YakindummPackage
import hu.bme.mit.inf.dslreasoner.ecore2logic.Ecore2Logic
import hu.bme.mit.inf.dslreasoner.ecore2logic.Ecore2LogicConfiguration
import hu.bme.mit.inf.dslreasoner.ecore2logic.Ecore2Logic_Trace
import hu.bme.mit.inf.dslreasoner.ecore2logic.EcoreMetamodelDescriptor
import hu.bme.mit.inf.dslreasoner.logic.model.builder.DocumentationLevel
import hu.bme.mit.inf.dslreasoner.logic.model.builder.TracedOutput
import hu.bme.mit.inf.dslreasoner.logic.model.logicproblem.LogicProblem
import hu.bme.mit.inf.dslreasoner.viatrasolver.logic2viatra.ModelGenerationMethod
import hu.bme.mit.inf.dslreasoner.viatrasolver.logic2viatra.ModelGenerationMethodProvider
import hu.bme.mit.inf.dslreasoner.viatrasolver.logic2viatra.ScopePropagator
import hu.bme.mit.inf.dslreasoner.viatrasolver.logic2viatra.TypeInferenceMethod
import hu.bme.mit.inf.dslreasoner.viatrasolver.partialinterpretation2logic.InstanceModel2PartialInterpretation
import hu.bme.mit.inf.dslreasoner.viatrasolver.partialinterpretationlanguage.partialinterpretation.BinaryElementRelationLink
import hu.bme.mit.inf.dslreasoner.viatrasolver.partialinterpretationlanguage.partialinterpretation.PartialComplexTypeInterpretation
import hu.bme.mit.inf.dslreasoner.viatrasolver.partialinterpretationlanguage.partialinterpretation.PartialInterpretation
import java.util.LinkedList
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EEnum
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.eclipse.emf.ecore.xmi.impl.XMIResourceFactoryImpl
import org.eclipse.viatra.query.runtime.api.IPatternMatch
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.api.ViatraQueryMatcher
import org.eclipse.viatra.query.runtime.emf.EMFScope
import org.eclipse.viatra.query.runtime.rete.matcher.ReteEngine

class ModelLoader {
	val ecore2Logic = new Ecore2Logic
	val modelGenerationMethod = new ModelGenerationMethodProvider

	def loadModel(String path) {
		val rs = new ResourceSetImpl
		val r = rs.getResource(URI.createURI(path), true)
		return r
	}

	def static void main(String[] args) {
		ReteEngine.getClass();
		YakindummPackage.eINSTANCE.eClass
		Resource.Factory.Registry.INSTANCE.extensionToFactoryMap.put("xmi", new XMIResourceFactoryImpl)

		val loader = new ModelLoader
		val modelinstancesURI = "instancemodels/ICSE2020-InstanceModels/yakindumm/human/humanInput100/run1/"
		val model = loader.loadModel(modelinstancesURI + "1.xmi")
		val partialmodel = loader.model2PartialModel(model)

//		for (element : partialmodel.newElements) {
//			print(element.name)
//			
//		}
//		
		
		
//		for (type : partialmodel.partialtypeinterpratation.filter(PartialComplexTypeInterpretation)) {
//			print(type.interpretationOf.name)
//			print(" > ")
//			println(type.elements.size)
//			for (element : type.elements) {
//				println(" > " + element.name)
//			}
//		}
		
		val containmentRelations = partialmodel.problem.containmentHierarchies.head.containmentRelations.toSet

		for (relation : partialmodel.partialrelationinterpretation) {
			println(relation.interpretationOf.name + ": " + relation.relationlinks.size)
			for (element : relation.relationlinks.filter(BinaryElementRelationLink)) {
				print(element.param1.name)
				if (containmentRelations.contains(relation.interpretationOf)) {
					print(" => ")
				} else {
					print(" -> ")
				}
				println(element.param2.name)
			}

		}

//		for (contents : partialmodel.eAllContents.toIterable){
//			print(contents)
//			print("\n")
//		}
	}

	def model2PartialModel(Resource model) {
		val metamodelDescriptor = new EcoreMetamodelDescriptor(
			YakindummPackage.eINSTANCE.EClassifiers.filter(EClass).toList,
			emptySet,
			false,
			YakindummPackage.eINSTANCE.EClassifiers.filter(EEnum).toList,
			YakindummPackage.eINSTANCE.EClassifiers.filter(EEnum).map[ELiterals].flatten.toList,
			YakindummPackage.eINSTANCE.EClassifiers.filter(EClass).map[EReferences].flatten.toList,
			emptyList
		)

		val metamodelProblem = ecore2Logic.transformMetamodel(metamodelDescriptor, new Ecore2LogicConfiguration)
		val partialModel = (new InstanceModel2PartialInterpretation).transform(metamodelProblem, model, true)
		partialModel.problemConainer = metamodelProblem.output

		// createMethod(metamodelProblem, partialModel)
		return partialModel

	// partialModel.problemConainer.elements.remove()
	}

	protected def void createMethod(TracedOutput<LogicProblem, Ecore2Logic_Trace> metamodelProblem,
		PartialInterpretation partialModel) {
		val modelGenerationMethod = modelGenerationMethod.createModelGenerationMethod(
			metamodelProblem.output,
			partialModel,
			null,
			false,
			TypeInferenceMethod.PreliminaryAnalysis,
			new ScopePropagator(partialModel),
			DocumentationLevel.NONE
		)

		val ViatraQueryEngine engine = ViatraQueryEngine.on(new EMFScope(partialModel))
		val matchers = new LinkedList

		printPatterns(modelGenerationMethod, matchers, engine)
	}

	protected def void printPatterns(ModelGenerationMethod modelGenerationMethod,
		LinkedList<ViatraQueryMatcher<? extends IPatternMatch>> matchers, ViatraQueryEngine engine) {
		println("\n--- PatternName -> EntitiesInPattern ---")
		for (p : modelGenerationMethod.allPatterns) {
			println(p.fullyQualifiedName + "/" + (p.parameters.size + 1))
			matchers += p.getMatcher(engine)
		}

		println("\n--- PatternName -> CountMatches ---")
		for (matcher : matchers) {
			println('''«matcher.patternName» -> «matcher.countMatches»''')
		}
	}
}
