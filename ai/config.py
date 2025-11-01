class Config:
    """Simple configuration class for MANIQA model"""
    
    def __init__(self, config_dict):
        for key, value in config_dict.items():
            setattr(self, key, value)
    
    def __getitem__(self, key):
        return getattr(self, key)
    
    def __setitem__(self, key, value):
        setattr(self, key, value)
