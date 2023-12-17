import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app_template/main.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

class StarParticle {
  vector_math.Vector2 pos = vector_math.Vector2(0, 0);
  vector_math.Vector2 velocity = vector_math.Vector2(0, 0);
  vector_math.Vector2 acceleration = vector_math.Vector2(0, 0);

  double size = 4;
  Color color = Colors.white;

  Size _canvasSize = Size.zero;
  double _accelerationValue = 0.0;
  double _maxSize = 0.0;

  double maxZ = 500;
  double minZ = 1;

  StarParticle(
    Size canvasSize, {
    double? circleRadius,
    double baseAcceleration = 0.0005,
    double maxSize = 0.0,
    bool randomZ = true,
  }) {
    _canvasSize = canvasSize;
    _accelerationValue = baseAcceleration;
    _maxSize = maxSize;

    resetPosition();

    if (circleRadius != null) {
      initAroundCircle(circleRadius);
    } else {
      initRandomly(canvasSize);
    }

    setSize();
  }

  void resetPosition() {
    pos = vector_math.Vector2(0, 0);
    velocity = vector_math.Vector2(0, 0);
    acceleration = vector_math.Vector2(0, 0);
  }

  void setSize() {
    size = random.nextDouble() * _maxSize;
  }

  void initRandomly(Size canvasSize) {
    pos = vector_math.Vector2(
      (-1 + random.nextDouble() * 2) * canvasSize.width / 2,
      (-1 + random.nextDouble() * 2) * canvasSize.height / 2,
    );
    acceleration = pos.clone()
      ..multiply(
        vector_math.Vector2(
          random.nextDouble() * _accelerationValue,
          random.nextDouble() * _accelerationValue,
        ),
      );
  }

  void initAroundCircle(double circleRadius) {
    /// Pick random angle around the circle
    var angle = random.nextDouble() * pi * 2;

    /// Plot this particle around edge of the circle
    pos = vector_math.Vector2(
      cos(angle) * circleRadius,
      sin(angle) * circleRadius,
    );

    acceleration = pos.clone()
      ..multiply(
        vector_math.Vector2(
          random.nextDouble() * _accelerationValue,
          random.nextDouble() * _accelerationValue,
        ),
      );
  }

  update(double bass) {
    if (bass.round() == 0) {
      vector_math.Vector2 add = acceleration;
      velocity.add(add);
    } else {
      double value = _accelerationValue + (bass * 1.2);
      vector_math.Vector2 add = acceleration..multiply(vector_math.Vector2(value, value));
      velocity.add(add);
    }

    pos.add(velocity);
  }

  /// If particle goes off screen
  bool shouldCull() {
    if (pos.x < -_canvasSize.width / 2 ||
        pos.x > _canvasSize.width / 2 ||
        pos.y < -_canvasSize.height / 2 ||
        pos.y > _canvasSize.height / 2) {
      return true;
    }
    return false;
  }
}
