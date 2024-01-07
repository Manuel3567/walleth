from google.cloud import firestore
from google.cloud.firestore_v1 import DocumentSnapshot, DocumentReference
from google.cloud.exceptions import Conflict

db = firestore.Client()
domain = "googlemail.com"
print("new")

users_coll = db.collection("domains").document(domain).collection("users")
res = users_coll.get()
print(res)
