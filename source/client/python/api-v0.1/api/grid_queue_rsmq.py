import rsmq
import json
import logging

logging.basicConfig(format="%(asctime)s - %(levelname)s - %(filename)s - %(funcName)s  - %(lineno)d - %(message)s",
                    datefmt='%H:%M:%S', level=logging.INFO)


class QueueRSMQ:

    def __init__(self, endpoint_url, queue_name):
        # Accept endpoint_url with the following format:
        # http://host:port
        if '//' in endpoint_url:
            endpoint_url = endpoint_url.split("//")[-1]

        [self.host, self.port] = endpoint_url.split(":")
        self.queue_name = queue_name

        try:
            self.queue = rsmq.RedisSMQ(host=self.host, port=self.port, qname=self.queue_name)
            self.queue.createQueue(vt=40, delay=0).execute()
            logging.info("Initializing QueueRSMQ: queue_endpoint_url={}, queue_name={}".format(endpoint_url, queue_name))
        except rsmq.cmd.exceptions.QueueAlreadyExists:
            logging.warning("QueueSQS: is already create: queue_name [{}], endpoint_url [{}]".format(queue_name, endpoint_url))
            pass
        except Exception as e:
            logging.error("QueueSQS: cannot connect to queue_name [{}], endpoint_url [{}] : {}".format(queue_name, endpoint_url, e))
            raise e

    def send_message(self, message_body):
        response = self.queue.sendMessage(message=message_body).execute()
        return response

    # Single write &  Batch write
    def send_messages(self, message_bodies=None, message_attributes={}):
        if message_bodies is None:
            message_bodies = []
        responses = {
            'Successful': [],
            'Failed': [],
        }

        for body in message_bodies:
            try:
                id = self.send_message(body)
                responses['Successful'].append(id)
            except Exception:
                responses['Failed'].append(body)
        return responses

        # return {
        #     'Successful': [
        #         {
        #             'Id': str,
        #         }
        #     ],
        #     'Failed': [
        #         {
        #             'Id': str,
        #         }
        #     ]
        # }

    def receive_message(self, wait_time_sec=0):
        messages = self.queue.receiveMessage(quiet=True).exceptions(False).execute()

        if not messages:
            # No messages were returned
            return {}

        return {
                "body": json.loads(messages['message'])['MessageBody'],
                "properties": {
                    "message_handle_id": messages['id'],
                }
            }

    def delete_message(self, message_handle_id, task_priority=None):
        """Deletes message from the queue by the message_handle_id.
        Often this function is called when message is sucessfully consumed.

        Args:
        message_handle_id(str): the sqs handler associated of the message to be deleted
        task_priority(int): <Interface argument, not used in this class>

        Returns: None

        Raises: ClientError: if message can not be deleted
        """

        try:
            self.queue.deleteMessage(id=message_handle_id).execute()
        except rsmq.cmd.exceptions.RedisSMQException as e:
            logging.error("Cannot delete message {} : {}".format(message, e))
            raise e
        return None

    def change_visibility(self, message_handle_id, visibility_timeout_sec, task_priority=None):
        """Changes visibility timeout of the message by its handle

        Args:
        message_handle_id(str): the sqs handler associated of the message to be deleted
        task_priority(int): <Interface argument, not used in this class>

        Returns: None

        Raises: ClientError: on failure
        """

        try:
            self.queue.changeMessageVisibility(
                vt=visibility_timeout_sec,
                id=message_handle_id,
            ).execute()
        except rsmq.cmd.exceptions.RedisSMQException as e:
            logging.error("Cannot reset VTO for message {} : {}".format(message_handle_id, e))
            raise e
        return None

    def get_queue_length(self):
        queue_length = int(self.queue.getQueueAttributes().execute()['msgs'])
        return queue_length