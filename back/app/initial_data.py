from app.database import SessionLocal, engine, Base
from app.models import User, Album, Image, Category, Tag # Added Tag
from app.models.album import AlbumType
from app.models.image import AIProcessingStatus
from app.security import get_password_hash

def seed_data():
    db = SessionLocal()
    try:
        # 데이터가 이미 있는지 확인
        if db.query(User).first() is None:
            print("Seeding initial data...")

            # Categories 생성
            category_landscape = Category(name="landscape")
            category_people = Category(name="people")
            category_animal = Category(name="animal")
            category_food = Category(name="food")
            category_city = Category(name="city")
            category_custom = Category(name="custom") # Added a custom category

            db.add_all([category_landscape, category_people, category_animal, category_food, category_city, category_custom])
            db.commit()

            # Refresh categories to get their IDs
            db.refresh(category_landscape)
            db.refresh(category_people)
            db.refresh(category_animal)
            db.refresh(category_food)
            db.refresh(category_city)
            db.refresh(category_custom)

            # Tags 생성 (using category_id)
            tag_mountain = Tag(name="mountain", category_id=category_landscape.id, user_id=None)
            tag_beach = Tag(name="beach", category_id=category_landscape.id, user_id=None)
            tag_dog = Tag(name="dog", category_id=category_animal.id, user_id=None)
            tag_cat = Tag(name="cat", category_id=category_animal.id, user_id=None)
            tag_pizza = Tag(name="pizza", category_id=category_food.id, user_id=None)
            tag_burger = Tag(name="burger", category_id=category_food.id, user_id=None)

            db.add_all([tag_mountain, tag_beach, tag_dog, tag_cat, tag_pizza, tag_burger])
            db.commit()

            # 사용자 생성
            user1 = User(username="user1", email="user1@example.com", password=get_password_hash("11111111"))
            user2 = User(username="user2", email="user2@example.com", password=get_password_hash("22222222"))

            db.add_all([user1, user2])
            db.commit()

            # 이미지 생성 (사용자 생성 후)
            db.refresh(user1)
            db.refresh(user2)

            image1 = Image(user_id=user1.id, url="https://images.pexels.com/photos/45201/kitty-cat-kitten-pet-45201.jpeg", hash="hash1", size=1024, ai_embedding="vector1", ai_processing_status=AIProcessingStatus.COMPLETED)
            image2 = Image(user_id=user1.id, url="https://images.pexels.com/photos/1108099/pexels-photo-1108099.jpeg", hash="hash2", size=2048, ai_embedding="vector2", ai_processing_status=AIProcessingStatus.COMPLETED)
            image3 = Image(user_id=user2.id, url="https://images.pexels.com/photos/326012/pexels-photo-326012.jpeg", hash="hash3", size=1536, ai_embedding="vector3", ai_processing_status=AIProcessingStatus.COMPLETED)

            db.add_all([image1, image2, image3])
            db.commit()

            # 앨범 생성 (이미지 생성 후)
            db.refresh(image1)
            db.refresh(image2)
            db.refresh(image3)

            album1 = Album(user_id=user1.id, cover_image_id=image1.id, name="User 1's Travel Album", type=AlbumType.TRAVEL, description="A travel album")
            album2 = Album(user_id=user1.id, cover_image_id=image2.id, name="User 1's Food Album", type=AlbumType.FOOD, description="A food album")
            album3 = Album(user_id=user2.id, cover_image_id=image3.id, name="User 2's Custom Album", type=AlbumType.CUSTOM, description="A custom album")

            db.add_all([album1, album2, album3])
            db.commit()

            print("Initial data seeded.")
        else:
            print("Data already exists, skipping seeding.")

    finally:
        db.close()

if __name__ == "__main__":
    seed_data()