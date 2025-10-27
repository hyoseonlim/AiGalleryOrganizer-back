# pip install timm, torch, transformers, tf-keras

import os
os.environ["TF_USE_LEGACY_KERAS"] = "1"

from urllib.request import urlopen
from PIL import Image
import timm
import torch
import json
from transformers import pipeline

label_url = 'https://s3.amazonaws.com/deep-learning-models/image-models/imagenet_class_index.json'
label_file = 'imagenet_class_index.json'

img = Image.open(urlopen(
    'https://d206helh22e0a3.cloudfront.net/images/brow/combo/combo.png'
)).convert('RGB')

if not os.path.exists(label_file):
    print(f"{label_file}을 다운로드합니다...")
    with urlopen(label_url) as response, open(label_file, 'wb') as out_file:
        out_file.write(response.read())
        
with open(label_file, "r") as f:
    class_idx = json.load(f)
    # 딕셔너리의 value(클래스 이름 리스트)만 추출하여 리스트로 만듭니다.
    imagenet_labels = [class_idx[str(k)][1] for k in range(len(class_idx))]

model = timm.create_model('mobilenetv3_small_100.lamb_in1k', pretrained = True)
model = model.eval()

data_config = timm.data.resolve_model_data_config(model)
transforms =timm.data.create_transform(**data_config, is_training = False)

output = model(transforms(img).unsqueeze(0))

top5_probabilities, top5_class_indices = torch.topk(output.softmax(dim=1) * 100, k=5)

classifier = pipeline("zero-shot-classification",
                      model="facebook/bart-large-mnli")

candidate_labels = ['Happy date with my boyfriend Minsu', 'dinner', 'travel', 'landscape']

print("\n--- 상위 5개 예측 결과 ---")
for i in range(top5_class_indices.size(1)):
    class_name = imagenet_labels[top5_class_indices[0][i]]
    probability = top5_probabilities[0][i].item()
    print(f"{i+1}. 클래스: {class_name:<20} | 확률: {probability:.2f}%")
    
    hierar = classifier(class_name, candidate_labels, multi_label = True)
    print(hierar)
    for i in range(len(candidate_labels)):
        print(f"추천 상위 태그: {hierar['labels'][i]}, 확률: {hierar['scores'][i] * 100}%")
    
    
