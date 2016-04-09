//
//  Shaders.metal
//  SoftRenderer
//
//  Created by Princerin on 4/2/16.
//  Copyright (c) 2016 Princerin. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

struct VertexIn
{
    packed_float3 position;
    packed_float4 color;
    float pointSize;
};

struct VertexInOut
{
    float4  position [[position]];
    float4  color;
    float pointSize [[point_size]];
};

vertex VertexInOut passThroughVertex(uint vid [[ vertex_id ]],
                                     constant VertexIn* vertexIn  [[ buffer(0) ]])
{
    VertexInOut outVertex;
    
    outVertex.position = float4(vertexIn[vid].position, 1.0f);
    outVertex.color    = vertexIn[vid].color;
    outVertex.pointSize = vertexIn[vid].pointSize;
    
    return outVertex;
};

fragment half4 passThroughFragment(VertexInOut inFrag [[stage_in]])
{
    return half4(inFrag.color);
};