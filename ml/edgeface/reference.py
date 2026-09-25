"""Independent NumPy reference for the versioned Kotlin preprocessing contract."""
import numpy as np

TEMPLATE = np.array([[38.2946,51.6963],[73.5318,51.5014],[56.0252,71.7366],
                     [41.5493,92.3655],[70.7299,92.2041]], dtype=np.float64)

def align_tensor(rgb, points):
    points = np.asarray(points, dtype=np.float64)
    if points.shape != (5, 2) or not np.isfinite(points).all():
        raise ValueError('Invalid landmarks')
    # Independent least-squares linear solve, not the Kotlin closed-form formula.
    design = np.zeros((10, 4))
    design[0::2] = np.column_stack((points[:,0], -points[:,1], np.ones(5), np.zeros(5)))
    design[1::2] = np.column_stack((points[:,1], points[:,0], np.zeros(5), np.ones(5)))
    parameters, _, rank, _ = np.linalg.lstsq(design, TEMPLATE.reshape(-1), rcond=None)
    if rank != 4:
        raise ValueError('Degenerate landmarks')
    a,b,tx,ty = parameters
    matrix = np.array([[a,-b,tx],[b,a,ty],[0,0,1]])
    y,x = np.indices((112,112))
    src = np.linalg.inv(matrix) @ np.stack((x.ravel(),y.ravel(),np.ones(112*112)))
    sx,sy=src[:2]; ix=np.floor(sx).astype(int); iy=np.floor(sy).astype(int)
    fx=sx-ix; fy=sy-iy
    def sample(x,y):
        valid=(x>=0)&(y>=0)&(x<rgb.shape[1])&(y<rgb.shape[0])
        out=np.zeros((len(x),3)); out[valid]=rgb[y[valid],x[valid]]
        return out
    aligned=(sample(ix,iy)*((1-fx)*(1-fy))[:,None]+sample(ix+1,iy)*(fx*(1-fy))[:,None]+
             sample(ix,iy+1)*((1-fx)*fy)[:,None]+sample(ix+1,iy+1)*(fx*fy)[:,None])
    return (aligned.reshape(112,112,3).transpose(2,0,1)/127.5-1).astype(np.float32)[None]

def normalized(x):
    x=np.asarray(x,dtype=np.float64)
    if not np.isfinite(x).all() or np.linalg.norm(x)<1e-12:
        raise ValueError('Invalid embedding')
    return x/np.linalg.norm(x)

def assert_parity(reference, actual, cosine_min=0.9999, absolute_max=0.0001):
    a,b=normalized(reference).reshape(-1),normalized(actual).reshape(-1)
    cosine=float(a@b); error=float(np.max(np.abs(a-b)))
    if cosine<cosine_min or error>absolute_max:
        raise AssertionError(f'Parity failed: cosine={cosine}, max_abs={error}')
    return {'cosine':cosine,'max_absolute_normalized_error':error}

def synthetic_fixture():
    y,x=np.indices((160,160))
    rgb=np.stack(((x*3+y)%256,(y*5+x)%256,(x*7+y*11)%256),axis=-1).astype(np.uint8)
    return rgb,TEMPLATE*1.1+np.array([8,4])

if __name__=='__main__':
    from pathlib import Path
    root=Path(__file__).resolve().parents[2]
    out=root/'android/app/src/test/resources/preprocessing-golden.f32'
    out.parent.mkdir(parents=True,exist_ok=True)
    align_tensor(*synthetic_fixture()).astype('<f4').tofile(out)
    print(f'Wrote independent Python golden tensor: {out.name}')
