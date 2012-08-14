try:
    import json
except ImportError:
    import sys
    sys.path.append('simplejson-2.3.3')
    import simplejson as json
    
import urllib



class InvocationService:

    def __init__(self, url):
        if url != None:
            self.url = url

    def start_session(self, session_id):

        arg_hash = { 'method': 'InvocationService.start_session',
                     'params': [session_id],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result'][0]
        else:
            return None

    def valid_session(self, session_id):

        arg_hash = { 'method': 'InvocationService.valid_session',
                     'params': [session_id],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result'][0]
        else:
            return None

    def list_files(self, session_id, cwd, d):

        arg_hash = { 'method': 'InvocationService.list_files',
                     'params': [session_id, cwd, d],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result']
        else:
            return None

    def remove_files(self, session_id, cwd, filename):

        arg_hash = { 'method': 'InvocationService.remove_files',
                     'params': [session_id, cwd, filename],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result']
        else:
            return None

    def rename_file(self, session_id, cwd, from, to):

        arg_hash = { 'method': 'InvocationService.rename_file',
                     'params': [session_id, cwd, from, to],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result']
        else:
            return None

    def copy(self, session_id, cwd, from, to):

        arg_hash = { 'method': 'InvocationService.copy',
                     'params': [session_id, cwd, from, to],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result']
        else:
            return None

    def make_directory(self, session_id, cwd, directory):

        arg_hash = { 'method': 'InvocationService.make_directory',
                     'params': [session_id, cwd, directory],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result']
        else:
            return None

    def remove_directory(self, session_id, cwd, directory):

        arg_hash = { 'method': 'InvocationService.remove_directory',
                     'params': [session_id, cwd, directory],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result']
        else:
            return None

    def change_directory(self, session_id, cwd, directory):

        arg_hash = { 'method': 'InvocationService.change_directory',
                     'params': [session_id, cwd, directory],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result']
        else:
            return None

    def put_file(self, session_id, filename, contents, cwd):

        arg_hash = { 'method': 'InvocationService.put_file',
                     'params': [session_id, filename, contents, cwd],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result']
        else:
            return None

    def get_file(self, session_id, filename, cwd):

        arg_hash = { 'method': 'InvocationService.get_file',
                     'params': [session_id, filename, cwd],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result'][0]
        else:
            return None

    def run_pipeline(self, session_id, pipeline, input, max_output_size, cwd):

        arg_hash = { 'method': 'InvocationService.run_pipeline',
                     'params': [session_id, pipeline, input, max_output_size, cwd],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result']
        else:
            return None

    def exit_session(self, session_id):

        arg_hash = { 'method': 'InvocationService.exit_session',
                     'params': [session_id],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result']
        else:
            return None

    def valid_commands(self, ):

        arg_hash = { 'method': 'InvocationService.valid_commands',
                     'params': [],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result'][0]
        else:
            return None

    def get_tutorial_text(self, step):

        arg_hash = { 'method': 'InvocationService.get_tutorial_text',
                     'params': [step],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result']
        else:
            return None




        
