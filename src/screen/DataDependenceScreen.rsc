module screen::DataDependenceScreen

import Prelude;
import lang::java::jdt::m3::Core;
import analysis::graphs::Graph;
import vis::Figure;
import vis::Render;
import vis::KeySym;
import util::Editors;
import lang::java::m3::AST;

import screen::Screen;
import extractors::Project;

import creator::CFGCreator;
import graph::DataStructures;
import graph::\data::DDG;

@doc {
	To run a test:
		displayDataDependenceGraph(|project://pdg-JavaTest|, "testPDT");
		displayDataDependenceGraph(|project://pdg-JavaTest|, "testPDT2");
		displayDataDependenceGraph(|project://QL|, "nextToken");
}
public void displayDataDependenceGraph(loc project, str methodName) {
	M3 projectModel = createM3(project);
	loc methodLocation = getMethodLocation(methodName, projectModel);
	node methodAST = getMethodASTEclipse(methodLocation, model = projectModel);
	
	MethodData methodData = emptyMethodData();
	methodData.name = methodName;
	methodData.abstractTree = methodAST;
	
	list[MethodData] methodCollection = createControlFlows(methodLocation, methodData, projectModel);
	methodCollection = [ createDDG(method) | method <- methodCollection ];
	
	list[Edge] edges = [];
	list[Figure] boxes = [];
	
	for(method <- methodCollection) {
		edges += createEdges(method.name, method.dataDependence.graph, "dash", "green");
		
		boxes += createBoxes(method);
		boxes += box(text("ENTRY <method.name>"), id("<method.name>:<ENTRYNODE>"), size(50), fillColor("lightblue"));
	}
	
	render(graph(boxes, edges, hint("layered"), gap(50)));
}