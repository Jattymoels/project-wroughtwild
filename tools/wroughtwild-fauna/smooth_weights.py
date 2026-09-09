"""Connected-mesh weight diffusion for the two fitted ART-03 animal skins.

Keep authored rigid anchors. This corrects spatial-mask seams, not mesh topology.
"""
import numpy as np

def smooth_fitted_weights(mesh_object, rigid_skull_mask, passes):
    count=len(mesh_object.data.vertices)
    groups=list(mesh_object.vertex_groups)
    weights=np.zeros((count,len(groups)),dtype=float)
    for v in mesh_object.data.vertices:
        for g in v.groups: weights[v.index,g.group]=g.weight
    locked=np.array(rigid_skull_mask,dtype=bool).copy()
    for g in groups:
        if g.name.endswith('_hoof'):locked|=weights[:,g.index]>.999
    original=weights.copy()
    edges=np.array([e.vertices[:] for e in mesh_object.data.edges],dtype=int)
    src=np.concatenate([edges[:,0],edges[:,1]])
    dst=np.concatenate([edges[:,1],edges[:,0]])
    degree=np.bincount(src,minlength=count).clip(1)[:,None]
    for _ in range(passes):
        average=np.zeros_like(weights)
        for column in range(weights.shape[1]):
            average[:,column]=np.bincount(src,weights=weights[dst,column],minlength=count)
        weights=weights*.5+(average/degree)*.5
        weights[locked]=original[locked]
    # GLB accepts four influences. Restore exact sums after retaining the largest.
    top=np.argsort(weights,axis=1)[:,-4:]
    kept=np.zeros_like(weights)
    rows=np.arange(count)[:,None]
    kept[rows,top]=weights[rows,top]
    kept/=kept.sum(axis=1)[:,None]
    indices=list(range(count))
    for group in groups:group.remove(indices)
    for index in range(count):
        for column in top[index]:
            weight=float(kept[index,column])
            if weight>1e-7:groups[int(column)].add([index],weight,'REPLACE')
