from base_info import Base_info
from extensions import db

class Restricoes(Base_info):
    alergias = db.Column(db.Text, nullable = False)
    

    