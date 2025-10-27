# pip install timm, torch, transformers, tf-keras, pillow

import os
os.environ["TF_USE_LEGACY_KERAS"] = "1"

from transformers import MobileViTFeatureExtractor, MobileViTForImageClassification
from PIL import Image
import requests
from urllib.request import urlopen

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
predicted_class_idx = logits.argmax(-1).item()
print("Predicted class:", model.config.id2label[predicted_class_idx])