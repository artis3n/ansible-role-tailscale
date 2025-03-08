from ansible.utils.display import Display


class FilterModule(object):
    def filters(self): return {'print_warn': self.warn_filter}

    def warn_filter(self, message, **kwargs):
        lines = message.splitlines()
        for line in lines:
            Display().warning(line)
        return message
