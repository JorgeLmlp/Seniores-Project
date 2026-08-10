from base_info import Base_info
from extensions import db




class DiarioSaude(Base_info):
    humor = db.Column(db.Enum())
    descHumor = db.column()
    dor = db.Column()
    descDor = db.column(db.Text())
    Humor = db.Column()
    descHumor = db.column()
    