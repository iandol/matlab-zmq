classdef Context < handle

	properties (Access = private)
		contextPointer
		spawnedSockets
	end

	methods
		function obj = Context(varargin)
			if (nargin ~= 0)
				warning('zmq:Context:extraConstructArgs','Extraneous constructor arguments.');
			end
			% Core API
			obj.contextPointer = zmq.core.ctx_new();
			% Initi properties
			obj.spawnedSockets = {};
		end

		function delete(obj)
			if (obj.contextPointer ~= 0)
				for n = 1:length(obj.spawnedSockets)
					socketObj = obj.spawnedSockets{n};
					try %#ok<*TRYNC>
						socketObj.cleanup();
					end
				end
				zmq.core.ctx_shutdown(obj.contextPointer);
				obj.term;
			end
		end

		% This exposes the underlying context pointer.
		function ptr = get_ptr(obj)
			ptr = obj.contextPointer;
		end

		function option = get(obj, name)
			optName = obj.normalize_const_name(name);
			option = zmq.core.ctx_get(obj.contextPointer, optName);
		end

		function set(obj, name, value)
			optName = obj.normalize_const_name(name);
			zmq.core.ctx_set(obj.contextPointer, optName, value);
		end

		function newSocket = socket(obj, socketType)
			% Spawns a socket from the context
			newSocket = zmq.Socket(obj.contextPointer, socketType);
			% Keep tracking of spawned sockets
			% this is important to the cleanup process
			obj.spawnedSockets{end+1} = newSocket;
		end

		function term(obj)
			try zmq.core.ctx_term(obj.contextPointer); end
			obj.contextPointer = 0;  % ensure NULL pointer
		end

	end

	methods (Access = protected)
		function normalized = normalize_const_name(~, name)
			normalized = strrep(upper(name), 'ZMQ_', '');
			normalized = strcat('ZMQ_', normalized);
		end
	end
end
