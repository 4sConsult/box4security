def userConfirm():
    answer = input().lower().strip()
    if 'y' in answer or 'j' in answer:
        return True
    else:
        return False
