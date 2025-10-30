# pip install timm, torch, transformers, tf-keras, pillow, torchvision, nima, tensorflow, huggingface_hub, open_clip_torch, opencv-python

import os
os.environ["TF_USE_LEGACY_KERAS"] = "1"

from transformers import MobileViTFeatureExtractor, MobileViTForImageClassification, pipeline
from PIL import Image
from urllib.request import urlopen
import torch
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
import predict_one_image

#VIT model
#
feature_extractor = MobileViTFeatureExtractor.from_pretrained("apple/mobilevit-small")
model = MobileViTForImageClassification.from_pretrained("apple/mobilevit-small")
model.eval()
model.to(device)
#

#대분류 - 소분류 pairing model
##
classifier = pipeline("zero-shot-classification",
                      model="facebook/bart-large-mnli", device = 0)
##

#Image quality classify model
##############
#MANIQA와 연동#
##############

#feature_vector 추출 
####
feature_maps = {}
def get_features(name):
    def hook(model, input, output):
        if isinstance(output, tuple):
            feature_maps[name] = output[0].detach()
        else:
            feature_maps[name] = output.detach()
    return hook

target_layer_name = 'dropout'

try:
    target_layer = dict(model.named_modules())[target_layer_name]
    target_layer.register_forward_hook(get_features(target_layer_name))
    print(f"Feature Vector를 추출할 수 있습니다.")
except KeyError:
    print(f"오류: Feature Vector를 추출할 수 없습니다.")
####

#https://d206helh22e0a3.cloudfront.net/images/brow/combo/combo.png -> test용 image link
def main():
    img_url = 'https://d206helh22e0a3.cloudfront.net/images/brow/combo/combo.png'
    image = Image.open(urlopen('https://gogumafarm.kr/wp-content/uploads/2024/04/%ED%8F%AC%EC%BC%93%EB%AA%AC-%ED%83%80%EC%9A%B4_%ED%94%BC%EC%B9%B4%EC%B8%84%EB%A5%BC-%ED%83%9C%EC%9A%B4-%EB%8C%80%ED%98%95-%EB%9D%BC%ED%94%84%EB%9D%BC%EC%8A%A4.png')).convert('RGB')
    #임시 대분류 set
    candidate_labels = ['Happy date with my boyfriend Minsu', 'dinner', 'travel', 'landscape']

    inputs = feature_extractor(images=image, return_tensors="pt").to(device)
    with torch.no_grad():
        #tag
        outputs = model(**inputs)
        logits = outputs.logits
        quality_score = predict_one_image(img_url)
        #quality
    
    #tagging result
    #
    top_probability, top_class_index = torch.topk(logits.softmax(dim = 1) * 100, k = 1)

    for i in range(top_class_index.size(1)):
        class_name = model.config.id2label[top_class_index[0][i].item()]
        probability = top_probability[0][i]
        
        print(f"{i+1}. 클래스: {class_name} | 확률: {probability:.2f}%")

    if target_layer_name in feature_maps:
        extracted_features = feature_maps[target_layer_name]
        print(f"{extracted_features.size()}")
    else:
        print(f"'{target_layer_name}'에서 특징 맵을 가져오지 못했습니다.")
    #
    
    #hierarchy result
    ##
    hierar = classifier(class_name, candidate_labels, multi_label = True)
    print(f"추천 상위 태그: {hierar['labels'][0]}, 확률: {hierar['scores'][0] * 100:.2f}%")
    ##
    
    #quality result
    ###
    print(f"Quality score: {quality_score}")
    ###

    #답변
    answer = [class_name, probability, ]
    feature_answer = extracted_features
    
#실제 사용할때는 main에 이미지 링크를 받음.
#대분류 list set도 입력 받아야함.
if __name__ == "__main__":
    main()