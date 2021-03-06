// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:convert';

import 'package:test/test.dart';

import 'package:build/src/asset_graph/graph.dart';
import 'package:build/src/asset_graph/node.dart';

import '../common/common.dart';

void main() {
  group('AssetGraph', () {
    AssetGraph graph;

    setUp(() {
      graph = new AssetGraph()..validAsOf = new DateTime.now();
    });

    void expectNodeDoesNotExist(AssetNode node) {
      expect(graph.contains(node.id), isFalse);
      expect(graph.get(node.id), isNull);
    }

    void expectNodeExists(AssetNode node) {
      expect(graph.contains(node.id), isTrue);
      expect(graph.get(node.id), node);
    }

    AssetNode testAddNode() {
      var node = makeAssetNode();
      expectNodeDoesNotExist(node);
      graph.add(node);
      expectNodeExists(node);
      return node;
    }

    test('add, contains, get, allNodes', () {
      var expectedNodes = [];
      for (int i = 0; i < 5; i++) {
        expectedNodes.add(testAddNode());
      }
      expect(graph.allNodes, unorderedEquals(expectedNodes));
    });

    test('addIfAbsent', () {
      var node = makeAssetNode();
      expect(graph.addIfAbsent(node.id, () => node), same(node));
      expect(graph.contains(node.id), isTrue);

      var otherNode = new AssetNode(node.id);
      expect(graph.addIfAbsent(otherNode.id, () => otherNode), same(node));
      expect(graph.contains(otherNode.id), isTrue);
    });

    test('duplicate adds throw DuplicateAssetNodeException', () {
      var node = testAddNode();
      expect(() => graph.add(node), throwsA(duplicateAssetNodeException));
    });

    test('remove', () {
      var nodes = <AssetNode>[];
      for (int i = 0; i < 5; i++) {
        nodes.add(testAddNode());
      }
      graph.remove(nodes[1].id);
      graph.remove(nodes[4].id);

      expectNodeExists(nodes[0]);
      expectNodeDoesNotExist(nodes[1]);
      expectNodeExists(nodes[2]);
      expectNodeDoesNotExist(nodes[4]);
      expectNodeExists(nodes[3]);

      // Doesn't throw.
      graph.remove(nodes[1].id);

      // Can be added back
      graph.add(nodes[1]);
      expectNodeExists(nodes[1]);
    });

    test('serialize/deserialize', () {
      for (int n = 0; n < 5; n++) {
        var node = makeAssetNode();
        graph.add(node);
        for (int g = 0; g < 5 - n; g++) {
          var generatedNode =
              new GeneratedAssetNode(node.id, false, g % 2 == 0, makeAssetId());
          node.outputs.add(generatedNode.id);
          graph.add(generatedNode);
        }
      }

      var encoded = JSON.encode(graph.serialize());
      var decoded = new AssetGraph.deserialize(JSON.decode(encoded));
      expect(graph, equalsAssetGraph(decoded));
    });

    test('Throws an AssetGraphVersionError if versions dont match up', () {
      var serialized = graph.serialize();
      serialized['version'] = -1;
      var encoded = JSON.encode(serialized);
      expect(() => new AssetGraph.deserialize(JSON.decode(encoded)),
          throwsA(assetGraphVersionException));
    });
  });
}
