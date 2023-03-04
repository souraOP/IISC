import os
from iisc import UPLOAD_DIR


def handle_uploaded_file(file_name, task_name, username):
    user_dir = os.path.join(UPLOAD_DIR, str(username))
    if not os.path.exists(user_dir):
        os.mkdir(user_dir)

    task_dir = os.path.join(UPLOAD_DIR, str(username), str(task_name))
    if not os.path.exists(task_dir):
        os.mkdir(task_dir)

    with open(task_dir+'/'+file_name.name, 'wb+') as destination:
        for chunk in file_name.chunks():
            destination.write(chunk)

    # data_dir = UPLOAD_DIR / task_name
    return task_dir


if __name__ == '__main__':
    handle_uploaded_file(file_name="input.xlsx", task_name="task", username="sample")
