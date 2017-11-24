# GPU PRO 5的体积光

基于GPU PRO 5做的体积光
核心是对每个灯光渲染对应的模型（点光球体，SpotLight椎体，平行光面片）
然后对渲染的模型上的每个像素进行Ray Marching，
由于用CommandBuffer插入到灯光渲染的渲染队列后，
所以可以获取灯光生成的shadowmap并以此做出遮蔽光的效果

![](https://github.com/Tangoyzx/GpuPro5VL/blob/master/Assets/Gifs/VL.gif)