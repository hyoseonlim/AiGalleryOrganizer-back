import os
import random
import cv2
import requests

import torch
import numpy as np
from torchvision import transforms
from torch.utils.data import DataLoader
from tqdm import tqdm

from config import Config
from maniqa import MANIQA
from inference_process import ToTensor, Normalize

os.environ['CUDA_VISIBLE_DEVICES'] = '0'

def setup_seed(seed):
    random.seed(seed)
    os.environ['PYTHONHASHSEED'] = str(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    torch.backends.cudnn.benchmark = False
    torch.backends.cudnn.deterministic = True


class Image(torch.utils.data.Dataset):
    def __init__(self, image_path_or_array, transform, num_crops=20):
        super(Image, self).__init__()
        
        # PIL Image 객체인 경우
        if hasattr(image_path_or_array, 'convert'):
            from PIL import Image as PILImage
            self.img_name = "pil_image.jpg"
            pil_img = image_path_or_array
            self.img = np.array(pil_img).astype('float32') / 255
            self.img = np.transpose(self.img, (2, 0, 1))
        
        # URL인 경우
        elif isinstance(image_path_or_array, str) and image_path_or_array.startswith('https'):
            self.img_name = image_path_or_array.split('/')[-1]
            try:
                response = requests.get(image_path_or_array)
                response.raise_for_status()
                
                image_bytes = np.frombuffer(response.content, np.uint8)

                self.img = cv2.imdecode(image_bytes, cv2.IMREAD_COLOR)
                self.img = cv2.cvtColor(self.img, cv2.COLOR_BGR2RGB)
                self.img = np.array(self.img).astype('float32') / 255
                self.img = np.transpose(self.img, (2, 0, 1))
                
                if self.img is None:
                    raise
            except requests.exceptions.RequestException as e:
                raise
        
        # 로컬 파일 경로인 경우
        else:
            self.img_name = image_path_or_array.split('/')[-1]
            self.img = cv2.imread(image_path_or_array, cv2.IMREAD_COLOR)
            self.img = cv2.cvtColor(self.img, cv2.COLOR_BGR2RGB)
            self.img = np.array(self.img).astype('float32') / 255
            self.img = np.transpose(self.img, (2, 0, 1))

        self.transform = transform

        c, h, w = self.img.shape
        print(self.img.shape)
        new_h = 224
        new_w = 224

        self.img_patches = []
        for i in range(num_crops):
                top = np.random.randint(0, h - new_h)
                left = np.random.randint(0, w - new_w)
                patch = self.img[:, top: top + new_h, left: left + new_w]
                self.img_patches.append(patch)
            
        self.img_patches = np.array(self.img_patches)

    def get_patch(self, idx):
        patch = self.img_patches[idx]
        sample = {'d_img_org': patch, 'score': 0, 'd_name': self.img_name}
        if self.transform:
            sample = self.transform(sample)
        return sample

def main(img_input):
    """
    Args:
        img_input: URL string, file path string, or PIL Image object
    """
    cpu_num = 1
    os.environ['OMP_NUM_THREADS'] = str(cpu_num)
    os.environ['OPENBLAS_NUM_THREADS'] = str(cpu_num)
    os.environ['MKL_NUM_THREADS'] = str(cpu_num)
    os.environ['VECLIB_MAXIMUM_THREADS'] = str(cpu_num)
    os.environ['NUMEXPR_NUM_THREADS'] = str(cpu_num)
    torch.set_num_threads(cpu_num)

    setup_seed(20)

    # config file
    config = Config({
        # image path or object
        "image_path": img_input,

        # valid times
        "num_crops": 20,

        # model
        "patch_size": 8,
        "img_size": 224,
        "embed_dim": 768,
        "dim_mlp": 768,
        "num_heads": [4, 4],
        "window_size": 4,
        "depths": [2, 2],
        "num_outputs": 1,
        "num_tab": 2,
        "scale": 0.8,

        # checkpoint path
        ##########################
        #서버에 올라갈 경우 수정 필요#
        ##########################
        "ckpt_path": "/Users/relained/Downloads/ckpt_koniq10k.pt",
    })
    
    # data load
    Img = Image(image_path_or_array=config.image_path,
        transform=transforms.Compose([Normalize(0.5, 0.5), ToTensor()]),
        num_crops=config.num_crops)
    
    # model defination
    net = MANIQA(embed_dim=config.embed_dim, num_outputs=config.num_outputs, dim_mlp=config.dim_mlp,
        patch_size=config.patch_size, img_size=config.img_size, window_size=config.window_size,
        depths=config.depths, num_heads=config.num_heads, num_tab=config.num_tab, scale=config.scale)

    # 디바이스 설정 (CUDA, MPS, CPU)
    if torch.cuda.is_available():
        device = torch.device('cuda')
    elif torch.backends.mps.is_available():
        device = torch.device('mps')
    else:
        device = torch.device('cpu')
    
    net.load_state_dict(torch.load(config.ckpt_path, map_location=device), strict=False)
    net = net.to(device)

    avg_score = 0
    for i in tqdm(range(config.num_crops)):
        with torch.no_grad():
            net.eval()
            patch_sample = Img.get_patch(i)
            patch = patch_sample['d_img_org'].to(device)
            patch = patch.unsqueeze(0)
            score = net(patch)
            avg_score += score
        
    return (avg_score / config.num_crops)


if __name__ == '__main__':  
    # 테스트용 - 실제 사용 시에는 main() 함수를 직접 호출
    test_img_url = "https://d206helh22e0a3.cloudfront.net/images/brow/combo/combo.png"
    score = main(test_img_url)
    print(f"Quality Score: {score}")
    
    