//
// Copyright 2011-2015 Jeff Bush
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//


#pragma once

#include <Shader.h>

using namespace librender;

class ColorShader : public Shader
{
public:
	ColorShader()
		:	Shader(7, 8)
	{
	}

	void shadeVertices(vecf16_t *outParams, const vecf16_t *inAttribs, const void *,
        int) const override
	{
		// Position
		outParams[kParamX] = inAttribs[0];
		outParams[kParamY] = inAttribs[1];
		outParams[kParamZ] = inAttribs[2];
		outParams[kParamW] = splatf(1.0);

		// Color
		outParams[4] = inAttribs[3];
		outParams[5] = inAttribs[4];
		outParams[6] = inAttribs[5];
		outParams[7] = inAttribs[6];
	}

	void shadePixels(vecf16_t *outColor, const vecf16_t *inParams,
		const void *, const Texture * const *,
		unsigned short) const override
	{
		outColor[0] = inParams[0];
		outColor[1] = inParams[1];
		outColor[2] = inParams[2];
		outColor[3] = inParams[3];
	}
};
