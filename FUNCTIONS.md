
## Global fluid system functions ##
<table>
  <tr align="center">
	<td><b>Function
	<td><b>Definition
	<td><b>Arguments
	<td><b>Returns
  </tr>
  <tr align="center">
	<td>fluidsystem.new
	<td>Creates a new fluid system
	<td>fluid parameter table (PARAMETERS.md)
	<td>fluidsystem
  </tr>
  <tr align="center">
	<td>fluidsystem.update
	<td>Updates all fluid system simulations
	<td>delta time
	<td>nil
  </tr>
  <tr align="center">
	<td>fluidsystem.draw
	<td>Renders all fluid systems
	<td>nil
	<td>nil
  </tr>
  <tr align="center">
	<td>fluidsystem.get
	<td>Returns a reference to a specified fluid system
	<td>id
	<td>fluidsystem
  </tr>
  <tr align="center">
	<td>fluidsystem.destroy
	<td>Destroys a specified fluid system
	<td>id
	<td>nil
  </tr>
  <tr align="center">
	<td>fluidsystem.assignBoxCollider
	<td>Assigns a box collider to a specified object
	<td>object, w, h, mass, static, ox, oy
	<td>fluidcollider
  </tr>
  <tr align="center">
	<td>fluidsystem.assignCircleCollider
	<td>Assigns a circle collider to a specified object
	<td>object, radius, mass, static, offset x, offset y
	<td>fluidcollider
  </tr>
  <tr align="center">
	<td>fluidsystem.assignPixelCollider
	<td>Assigns a pixel collider to a specified object
	<td>object, scale x, scale y, imagedata, mass, static, offset x, offset y
	<td>fluidcollider
  </tr>
  <tr align="center">
	<td>fluidsystem.boxCollision
	<td>Performs a box collision test
	<td>collider a, collider b
	<td>boolean
  </tr>
  <tr align="center">
	<td>fluidsystem.circleCollision
	<td>Performs a circle collision test
	<td>collider a, collider b
	<td>boolean
  </tr>
  <tr align="center">
	<td>fluidsystem.pixelCollision
	<td>Performs a pixel collision test
	<td>collider a, collider b
	<td>boolean
  </tr>
  <tr align="center">
	<td>fluidsystem.boxResolution
	<td>Resolves collision for a box collider
	<td>collider a, collider b, friction, damping
	<td>nil
  </tr>
  <tr align="center">
	<td>fluidsystem.innerBoxResolution
	<td>Resolves collision for the inside edges of a box collider
	<td>collider a, collider b, friction
	<td>nil
  </tr>
  <tr align="center">
	<td>fluidsystem.circleResolution
	<td>Resolves collision for a circle collider
	<td>collider a, collider b, damping
	<td>float, float
  </tr>
  <tr align="center">
	<td>fluidsystem.pixelResolution
	<td>Resolves collision for a pixel collider
	<td>collider a, collider b
	<td>nil
  </tr>
  <tr align="center">
	<td>fluidsystem.confineResolution
	<td>Confines a collider in a given area
	<td>collider, friction, x, y, width, height
	<td>nil
  </tr>
</table>

The collision functions have not been completely documented yet. There is commented guide to using these in the fluidsystem.lua file.

## Local fluid system methods ##
<table>
  <tr align="center">
	<td><b>Function
	<td><b>Definition
	<td><b>Arguments
	<td><b>Returns
  </tr>
  <tr align="center">
	<td>system:addParticle
	<td>Creates a new particle
	<td>x, y, velocity x, velocity y, color, radius, mass
	<td>particle
  </tr>
  <tr align="center">
	<td>system:removeParticle
	<td>Removes a particle from a system
	<td>id
	<td>nil
  </tr>
  <tr align="center">
	<td>system:removeAllParticles
	<td>Removes all particles in a system
	<td>nil
	<td>nil
  </tr>
  <tr align="center">
	<td>system:returnParticleCount
	<td>Returns the sum of particles in a system
	<td>nil
	<td>int
  </tr>
  <tr align="center">
	<td>system:applyImpulse
	<td>Applies an impulse to all particles in a system
	<td>x, y, force, radius
	<td>nil
  </tr>
  <tr align="center">
	<td>system:addAffector
	<td>Creates a new force affect in a system
	<td>x, y, force, radius
	<td>affector
  </tr>
  <tr align="center">
	<td>system:removeAffector
	<td>Removes an affector from a system
	<td>id
	<td>nil
  </tr>
  <tr align="center">
	<td>system:removeAllAffectors
	<td>Removes all affectors from a system
	<td>nil
	<td>nil
  </tr>
  <tr align="center">
	<td>system:returnAffectorCount
	<td>Returns the sum of affectors in a system
	<td>nil
	<td>int
  </tr>
  <tr align="center">
	<td>system:addCollider
	<td>Assigns a new fluid collider to a system
	<td>collider
	<td>collider
  </tr>
  <tr align="center">
	<td>system:removeCollider
	<td>Removes a collider from a system
	<td>collider
	<td>nil
  </tr>
  <tr align="center">
	<td>system:removeAllColliders
	<td>Removes all colliders from a system
	<td>nil
	<td>nil
  </tr>
  <tr align="center">
	<td>system:returnColliderCount
	<td>Returns the sum of colliders in a system
	<td>nil
	<td>int
  </tr>
  <tr align="center">
	<td>system:newQuad
	<td>Generates a new quad for the system's quadtree
	<td>x, y, width, height, level, parent quad
	<td>quad
  </tr>
  <tr align="center">
	<td>system:updateQuadtreeCollider
	<td>Validates a collider for the quadtree
	<td>collider
	<td>nil
  </tr>
  <tr align="center">
	<td>system:constructVectorTable
	<td>Takes in a table and filters out the x and y variables into a new table
	<td>table
	<td>table
  </tr>
  <tr align="center">
	<td>system:generateFluidshader
	<td>Generates a system's fluidshader
	<td>nil
	<td>nil
  </tr>
  <tr align="center">
	<td>system:updateFluidshader
	<td>Updates a system's fluidshader
	<td>nil
	<td>nil
  </tr>
  <tr align="center">
	<td>system:simulate
	<td>Calculates a frame of a system's simulation
	<td>delta time
	<td>nil
  </tr>
  <tr align="center">
	<td>system:draw
	<td>Draws a frame of a system's simulation
	<td>nil
	<td>nil
  </tr>
</table>