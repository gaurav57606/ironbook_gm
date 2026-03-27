import firebase_admin
from firebase_admin import credentials, firestore, auth
import json
import uuid
from datetime import datetime, timedelta

# Initialize Firebase (Assuming Emulator or Local GOOGLE_APPLICATION_CREDENTIALS)
try:
    firebase_admin.initialize_app()
except ValueError:
    pass # Already initialized

db = firestore.client()

def seed_data():
    json_path = r'c:\Users\PC\Desktop\series_project\project1\rev0\gym_sample_data.json'
    with open(json_path, 'r') as f:
        data = json.load(f)
    
    owners_data = data['gym_owners']
    members_data = data['members']
    
    # Map Owner IDs to real Firebase UIDs (placeholder or generated)
    owner_id_to_uid = {}
    
    print("--- SEEDING OWNERS ---")
    for owner in owners_data:
        email = f"owner{owner['owner_id']}@example.com"
        try:
            user = auth.get_user_by_email(email)
            uid = user.uid
        except:
            user = auth.create_user(email=email, password="password123")
            uid = user.uid
            
        owner_id_to_uid[owner['owner_id']] = uid
        print(f"Owner {owner['owner_id']} -> {uid} ({email})")
        
        # Seed ownerProfileCreated event
        event_id = str(uuid.uuid4())
        event_ref = db.collection('users').document(uid).collection('events').document(event_id)
        
        event_ref.set({
            'id': event_id,
            'entityId': 'owner',
            'eventType': 'ownerProfileCreated',
            'deviceId': 'seed-device',
            'deviceTimestamp': datetime.utcnow().isoformat() + 'Z',
            'synced': True,
            'payload': {
                'gymName': owner['gym_name'],
                'ownerName': owner['owner_name'],
                'phone': owner['phone']
            }
        })

    print("\n--- SEEDING MEMBERS ---")
    for member in members_data:
        owner_id = member['owner_id']
        uid = owner_id_to_uid.get(owner_id)
        if not uid: continue
        
        m_id = str(uuid.uuid4())
        event_id = str(uuid.uuid4())
        
        # Calculate expiry based on plan
        join_date = datetime.strptime(member['join_date'], "%Y-%m-%d")
        months = {
            "Monthly": 1,
            "Quarterly": 3,
            "Half-Yearly": 6,
            "Yearly": 12
        }.get(member['membership_type'], 1)
        
        expiry_date = join_date + timedelta(days=months * 30)
        
        event_ref = db.collection('users').document(uid).collection('events').document(event_id)
        event_ref.set({
            'id': event_id,
            'entityId': m_id,
            'eventType': 'memberCreated',
            'deviceId': 'seed-device',
            'deviceTimestamp': datetime.utcnow().isoformat() + 'Z',
            'synced': True,
            'payload': {
                'memberId': m_id,
                'name': member['full_name'],
                'phone': member['phone'],
                'planId': str(months),
                'planName': member['membership_type'],
                'joinDate': join_date.isoformat() + 'Z',
                'expiryDate': expiry_date.isoformat() + 'Z'
            }
        })
        
    print("\n--- SEEDING COMPLETED ---")

if __name__ == "__main__":
    seed_data()
