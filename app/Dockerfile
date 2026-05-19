FROM public.ecr.aws/lambda/python:3.12

COPY requirements.txt ${LAMBDA_TASK_ROOT}
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt 

COPY model.onnx class_info.json app.py ${LAMBDA_TASK_ROOT}

CMD ["app.lambda_handler"]