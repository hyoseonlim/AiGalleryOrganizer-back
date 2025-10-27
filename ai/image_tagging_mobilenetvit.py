# pip install timm, torch, transformers, tf-keras, pillow

import os
os.environ["TF_USE_LEGACY_KERAS"] = "1"

from transformers import MobileViTFeatureExtractor, MobileViTForImageClassification
from PIL import Image
import requests
from urllib.request import urlopen
import torch

image = Image.open(urlopen(
    'https://d206helh22e0a3.cloudfront.net/images/brow/combo/combo.png'
)).convert('RGB')

#VIT
feature_extractor = MobileViTFeatureExtractor.from_pretrained("apple/mobilevit-small")
model = MobileViTForImageClassification.from_pretrained("apple/mobilevit-small")
model.eval()

inputs = feature_extractor(images=image, return_tensors="pt")

outputs = model(**inputs)
logits = outputs.logits

# 예측되는 class
top5_probability, top5_class_index = torch.topk(logits.softmax(dim = 1) * 100, k = 5)

for i in range(top5_class_index.size(1)):
    class_name = model.config.id2label[top5_class_index[0][i].item()]
    probability = top5_probability[0][i]
    
    print(f"{i+1}. 클래스: {class_name:<20} | 확률: {probability:.2f}%")