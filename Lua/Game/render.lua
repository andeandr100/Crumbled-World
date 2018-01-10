--this=SceneNode.new()
function create()
	return true
end

function render(data)
	--data = RenderScene()
	
	if data:canRender3D() then
		data:beginRender3D()
		
		GL.disable(GL_State.BLEND)
		GL.enable(GL_State.CULL_FACE)
		GL.depthMask(true)
		
		data:render3D(1)--Defferd render object
		GL.disable(GL_State.CULL_FACE)
		data:render3D(3)--Defferd render object
						
		data:endRenderToDefferdBuffer()
		
		GL.enable(GL_State.BLEND)
		GL.blendEquation(GL_BlendEquation.FUNC_ADD);
		GL.blendFunc(GL_Blend.ONE,GL_Blend.ONE)
		GL.depthMask(false)
		GL.enable(GL_State.CULL_FACE)
		
		data:renderLight()
		
		if data:isMainCamera() then
			--Only render Target area on the main camera("monitor screen")
			GL.disable(GL_State.CULL_FACE)
			GL.blendFunc(GL_Blend.SRC_ALPHA,GL_Blend.ONE_MINUS_SRC_ALPHA)
			data:render3D(6)--Target area
			GL.enable(GL_State.CULL_FACE)
		end
		
		GL.enable(GL_State.BLEND)
		GL.blendEquation(GL_BlendEquation.FUNC_ADD);
		GL.blendFunc(GL_Blend.SRC_ALPHA,GL_Blend.ONE_MINUS_SRC_ALPHA)
		GL.depthMask(true)
		GL.disable(GL_State.CULL_FACE)
		data:render3D(0)--Space
		
		GL.enable(GL_State.BLEND)
		GL.depthMask(false)
		GL.blendFunc(GL_Blend.SRC_ALPHA,GL_Blend.ONE_MINUS_SRC_ALPHA)
		GL.disable(GL_State.CULL_FACE)
		
		data:render3D(10)--mine entrence, here should all effects thats need to be rendered before  force fileds be renderd
		data:render3D(4)--Distorion field
		
		
		GL.depthMask(true)
		
		data:render3D(2)--Spawn icon
		data:render3D(31)--Debug lines and Spheres

		
		GL.depthMask(false)
		--data:render3D(3)--Path render
			
		data:render3D(5)--Particle effects
		
		
		GL.depthMask(true)
				
		GL.enable(GL_State.CULL_FACE)
		data:render3D(9)--Npc reaper
		
		--render ghost towers
		GL.enable(GL_State.BLEND)
		GL.blendFuncSeparate( GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.ONE, GL_Blend.ONE);
		GL.blendEquation(GL_BlendEquation.FUNC_ADD)
		data:render3D(11)
		data:render3D(12)

		GL.depthMask(true)
		GL.blendEquation(GL_BlendEquation.FUNC_ADD);		
		GL.blendFunc(GL_Blend.ONE,GL_Blend.ONE)
		GL.disable(GL_State.BLEND)
		
		data:endRender3D()
	end
	
	GL.enable(GL_State.BLEND)
	GL.blendFuncSeparate( GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.ONE, GL_Blend.ONE);
	GL.blendEquation(GL_BlendEquation.FUNC_ADD)
	GL.enable(GL_State.BLEND)

	data:beginRender2D()
	
	data:render2D()
	
	data:endRender2D()

end

function update()	
	return true
end