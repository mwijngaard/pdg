@contributor{René Bulsing - UvA MSc 2015}
module graph::control::dependence::CDG

import Prelude;
import analysis::graphs::Graph;

import graph::DataStructures;


private map[int, int] getImmediatePostDominators(Graph[int] postDominator) {
	map[int, int] immediatePostDominators = ();
	
	immediatePostDominators[EXITNODE] = EXITNODE;
	for(<from, to> <- postDominator) {
		immediatePostDominators[to] = from;
	}
	
	return immediatePostDominators;
}

private Graph[int] augmentFlowGraph(ControlFlow controlFlow) {
	Graph[int] augmentedGraph = controlFlow.graph;
	
	augmentedGraph += { <STARTNODE, controlFlow.entryNode> };
	
	for(exitNode <- controlFlow.exitNodes) {
		augmentedGraph += { <exitNode, EXITNODE> };
	}
	
	augmentedGraph += { <ENTRYNODE, STARTNODE>, <ENTRYNODE, EXITNODE> };
	
	return augmentedGraph;
}

public ControlDependence createCDG(MethodData methodData, ControlFlow controlFlow, PostDominator postDominator) {
	ControlDependence controlDependence = ControlDependence({});
	Graph[int] augmentedGraph = augmentFlowGraph(controlFlow);
	
	// Maps a node to all the nodes that it depends on.
	map[int, set[int]] dependencies = ();
	// Maps a node to all the nodes that depend on it.
	map[int, set[int]] controls = ();
	
	for(treeNode <- carrier(augmentedGraph)) {
		dependencies[treeNode] = {};
		controls[treeNode] = {};
	}
	
	Graph[int] inspectionEdges = { <from, to> | <from, to> <- augmentedGraph, 
												from notin postDominator.dominations[to] };
												
	for(<from, to> <- inspectionEdges) {
		// Immediate dominator (idom)
		preds = predecessors(postDominator.tree, from);
		if (!isEmpty(preds)) {
			int idom = getOneFrom(preds);
			list[int] pathNodes = shortestPathPair(postDominator.tree, idom, to) - idom;
			
			for(pathNode <- pathNodes, pathNode != from) {
				dependencies[pathNode] += { from };
				controls[from] += { pathNode };
			}
		}
	}
	
	for(treeNode <- carrier(augmentedGraph) - { STARTNODE, EXITNODE, ENTRYNODE }) {
		if(treeNode > 0 && resolveIdentifier(methodData, treeNode)@nodeType == Parameter()) {
			controlDependence.graph += { <methodData.parameterNodes[treeNode], treeNode> };
			continue;
		}
		
		for(controller <- sort(dependencies[treeNode])) {
			if(size(dependencies[treeNode]) == 1 || (controls[controller] & dependencies[treeNode]) == {}) {
				controlDependence.graph += { <controller, treeNode> };
				break;
			}
		}
	}
	
	controlDependence.graph -= { <ENTRYNODE, STARTNODE> };
	
	return controlDependence;
}